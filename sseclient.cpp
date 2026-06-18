#include "sseclient.h"
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QDebug>

SSEClient::SSEClient(QObject *parent) : QObject(parent) {}

SSEClient::~SSEClient() {
    disconnectFromStream();
}

void SSEClient::setServerUrl(const QUrl &url) {
    if (m_serverUrl != url) {
        m_serverUrl = url;
        emit serverUrlChanged();
        if (m_active) connectToStream();
    }
}

void SSEClient::setActive(bool active) {
    if (m_active != active) {
        m_active = active;

        emit activeChanged();
        if (m_active) connectToStream();
        else disconnectFromStream();
    }
}

void SSEClient::connectToStream() {
    disconnectFromStream();
    if (m_serverUrl.isEmpty()) return;

    QNetworkRequest request(m_serverUrl);
    request.setRawHeader("Accept", "text/event-stream");
    request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::AlwaysNetwork);

    m_reply = m_nam.get(request);
    connect(m_reply, &QNetworkReply::readyRead, this, &SSEClient::handleReadyRead);
    connect(m_reply, &QNetworkReply::finished, this, &SSEClient::handleReplyFinished);

    qInfo() << "[SSE Client] Connected native pipeline to" << m_serverUrl.toString();
}

void SSEClient::disconnectFromStream() {
    if (m_reply) {
        m_reply->abort();
        m_reply->deleteLater();
        m_reply = nullptr;
        qInfo() << "[SSE Client] Native pipeline disconnected.";
    }
    m_buffer.clear();
}

void SSEClient::handleReadyRead() {
    if (!m_reply) return;
    m_buffer.append(m_reply->readAll());
    parseBuffer();
}

void SSEClient::handleReplyFinished() {
    qInfo() << "[SSE Client] Pipeline connection dropped by host. Retrying status:" << m_reply->error();
    // In production, trigger a reconnection timer here
}

void SSEClient::parseBuffer() {
    // SSE messages are explicitly delimited by double newlines
    int index;
    while ((index = m_buffer.indexOf("\n\n")) != -1) {
        QString block = QString::fromUtf8(m_buffer.left(index)).trimmed();
        m_buffer.remove(0, index + 2); // Discard the processed block and delimiter

        if (!block.isEmpty()) {
            processSSEMessage(block);
        }
    }
}

void SSEClient::processSSEMessage(const QString &block) {
    QStringList lines = block.split('\n');
    QString eventType = "message";
    QString dataPayload;

    for (const QString &line : lines) {
        if (line.startsWith("event:")) {
            eventType = line.mid(6).trimmed();
        } else if (line.startsWith("data:")) {
            dataPayload += line.mid(5).trimmed();
        }
    }

    QJsonObject jsonObj;
    if (!dataPayload.isEmpty()) {
        QJsonDocument doc = QJsonDocument::fromJson(dataPayload.toUtf8());
        if (!doc.isObject()) {
            qWarning() << "[SSE Client] Probably no payload:" << dataPayload;
        } else {
            jsonObj = doc.object();
        }
    }

    // Map string event types straight to performance-optimized native C++ Qt signals
    if (eventType == "settings_updated")       emit settingsUpdated(jsonObj);
    else if (eventType == "user_created")      emit userCreated(jsonObj);
    else if (eventType == "chore_created")     emit choreCreated(jsonObj);
    else if (eventType == "chore_completed")   emit choreCompleted(jsonObj);
    else if (eventType == "chore_approved")    emit choreApproved(jsonObj);
    else if (eventType == "chores_updated")    emit choresUpdated(jsonObj);
    else if (eventType == "calendar")          emit calendarChanged();
}