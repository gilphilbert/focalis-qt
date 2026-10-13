#ifndef INPUTFILTER_H
#define INPUTFILTER_H

#include <QObject>
#include <QEvent>
#include <QDateTime>
#include <qqmlintegration.h>

class InputFilter : public QObject {
    Q_OBJECT
    Q_PROPERTY(qint64 lastInputTime READ lastInputTime NOTIFY lastInputTimeChanged)

public:
    explicit InputFilter(QObject *parent = nullptr)
        : QObject(parent), m_lastInputTime(QDateTime::currentMSecsSinceEpoch()) {}

    static InputFilter* instance() {
        static InputFilter filterInstance;
        return &filterInstance;
    }

    qint64 lastInputTime() const {
        return m_lastInputTime;
    }

protected:
    bool eventFilter(QObject *watched, QEvent *event) override {
        switch (event->type()) {
        case QEvent::MouseButtonPress:
        case QEvent::TouchBegin:
        case QEvent::KeyPress: {
            qint64 currentTime = QDateTime::currentMSecsSinceEpoch();

            // Ignore duplicate triggers within 100ms of each other
            if (currentTime - m_lastInputTime > 100) {
                m_lastInputTime = currentTime;
                emit lastInputTimeChanged();
            }
            break;
        }
        default:
            break;
        }
        return QObject::eventFilter(watched, event);
    }

signals:
    void lastInputTimeChanged();

private:
    qint64 m_lastInputTime;
};

#endif // INPUTFILTER_H