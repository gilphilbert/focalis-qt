#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QFontDatabase>
#include <QFont>

#include "sseclient.h"
#include "InputFilter.h"

int main(int argc, char *argv[]) {
#ifndef QT_DEBUG
    qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));
    qputenv("QT_QPA_EGLFS_HIDECURSOR", QByteArray("1"));
    qputenv("QT_QPA_GENERIC_PLUGINS", QByteArray("evdevtouch,evdevmouse,evdevkeyboard"));
    qputenv("QT_QPA_PLATFORM", QByteArray("eglfs"));
    qputenv("QT_QPA_EGLFS_DISABLE_INPUT", QByteArray("1"));
#endif

    //qInfo() << "Current IM Module:" << qEnvironmentVariable("QT_IM_MODULE");

    QGuiApplication app(argc, argv);

    app.installEventFilter(InputFilter::instance());
    qmlRegisterSingletonInstance("focalis_ui", 1, 0, "InputFilter", InputFilter::instance());

    int fontId = QFontDatabase::addApplicationFont(":/fonts/Urbanist-VariableFont_wght.ttf");
    if (fontId != -1) {
        QStringList fontFamilies = QFontDatabase::applicationFontFamilies(fontId);
        if (!fontFamilies.isEmpty()) {
            QString familyName = fontFamilies.at(0);
            QFont customFont(familyName);
            app.setFont(customFont);
        }
    }

    // Register the SSE class as a native QML element before loading the engine
    qmlRegisterType<SSEClient>("Focalis.Core", 1, 0, "SSEClient");

    //engine.rootContext()->setContextProperty("inputFilter", &inputFilter);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("focalis_ui", "Main");

    return app.exec();
}
