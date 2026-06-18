#ifndef SSECLIENT_H
#define SSECLIENT_H

#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>

class SSEClient : public QObject {
    Q_OBJECT
    Q_PROPERTY(QUrl serverUrl READ serverUrl WRITE setServerUrl NOTIFY serverUrlChanged)
    Q_PROPERTY(bool active READ isActive WRITE setActive NOTIFY activeChanged)

public:
    explicit SSEClient(QObject *parent = nullptr);
    ~SSEClient();

    QUrl serverUrl() const { return m_serverUrl; }
    void setServerUrl(const QUrl &url);

    bool isActive() const { return m_active; }
    void setActive(bool active);

signals:
    void serverUrlChanged();
    void activeChanged();

    // Unified application signals mapped straight to your Go backend events
    void settingsUpdated(const QJsonObject &data);
    void userCreated(const QJsonObject &data);
    void choreCreated(const QJsonObject &data);
    void choreCompleted(const QJsonObject &data);
    void choreApproved(const QJsonObject &data);
    void choresUpdated(const QJsonObject &data);
    //void calendarItemCreated(const QJsonObject &data);
    void calendarChanged();

private slots:
    void connectToStream();
    void disconnectFromStream();
    void handleReadyRead();
    void handleReplyFinished();

private:
    void parseBuffer();
    void processSSEMessage(const QString &block);

    QNetworkAccessManager m_nam;
    QNetworkReply *m_reply = nullptr;
    QUrl m_serverUrl;
    bool m_active = false;
    QByteArray m_buffer;
};

#endif // SSECLIENT_H
