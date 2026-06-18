#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QFontDatabase>
#include <QFont>

#include "sseclient.h"

int main(int argc, char *argv[])
{
    qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));

    qInfo() << "Current IM Module:" << qEnvironmentVariable("QT_IM_MODULE");

    QGuiApplication app(argc, argv);

    int fontId = QFontDatabase::addApplicationFont(":/fonts/Urbanist-VariableFont_wght.ttf");
    if (fontId != -1) {
        QStringList fontFamilies = QFontDatabase::applicationFontFamilies(fontId);
        if (!fontFamilies.isEmpty()) {
            QString familyName = fontFamilies.at(0);
            QFont customFont(familyName);
            app.setFont(customFont);
        }
    }
    //QFontDatabase::addApplicationFont(":/fonts/Urbanist-SemiBold.ttf");
    //QFontDatabase::addApplicationFont(":/fonts/Urbanist-Bold.ttf");

    // Register the SSE class as a native QML element before loading the engine
    qmlRegisterType<SSEClient>("Focalis.Core", 1, 0, "SSEClient");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("homestead", "Main");

    return app.exec();
}
