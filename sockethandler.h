#ifndef SOCKETHANDLER_H
#define SOCKETHANDLER_H

#include <QObject>
#include <QLocalServer>
#include <QLocalSocket>
//#include <QtQml/QQmlRegistration> // Good practice in Qt 6

class SocketHandler : public QObject {
    Q_OBJECT
    // In Qt 6.2+, you can also just add QML_ELEMENT here instead of qmlRegisterType
public:
    explicit SocketHandler(QObject *parent = nullptr) : QObject(parent) {
        server = new QLocalServer(this);
        QLocalServer::removeServer("/tmp/homestead_trigger");

        if (server->listen("/tmp/homestead_trigger")) {
            connect(server, &QLocalServer::newConnection, this, &SocketHandler::handleConnection);
        }
    }

signals:
    void externalInterrupt();

private slots:
    void handleConnection() {
        QLocalSocket *clientSocket = server->nextPendingConnection();
        if (!clientSocket) return;

        emit externalInterrupt();

        connect(clientSocket, &QLocalSocket::disconnected, clientSocket, &QLocalSocket::deleteLater);

        // Qt 6 still benefits from ensuring the handshake finishes
        if (clientSocket->waitForReadyRead(100)) {
            clientSocket->readAll();
        }
        clientSocket->disconnectFromServer();
    }

private:
    QLocalServer *server;
};

#endif // SOCKETHANDLER_H
