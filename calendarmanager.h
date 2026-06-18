#ifndef CALENDARMANAGER_H
#define CALENDARMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QXmlStreamReader>
#include <QDateTime>
#include <QVariantList>

#include "ical_parser.h"

#include <QJsonArray>
#include <QJsonObject>
#include <QJsonDocument>

struct CalendarConfig {
    QString url;
    QString username;
    QString password;
};

class CalendarManager : public QObject {
    Q_OBJECT
public:
    explicit CalendarManager(QObject *parent = nullptr) : QObject(parent) {}

    // Retrieves events for the next 5 days
    Q_INVOKABLE void fetchEvents(const QString &url, const QString &user, const QString &pass, const int calId) {
        QNetworkAccessManager *manager = new QNetworkAccessManager(this);

        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/xml; charset=utf-8");
        request.setRawHeader("Depth", "1");

        // Basic Auth
        QString auth = QString("%1:%2").arg(user).arg(pass).toLocal8Bit().toBase64();
        request.setRawHeader("Authorization", "Basic " + auth.toLocal8Bit());

        // CalDAV REPORT query for a time range ///////////////////////////// neeeds to change to include all events for all 5 days, not just now() + 5 days! remove expansion for recurring events.
        QString start = QDateTime::currentDateTime().toString(Qt::ISODate).replace("-", "").replace(":", "");
        QString end = QDateTime::currentDateTime().addDays(5).toString(Qt::ISODate).replace("-", "").replace(":", "");

        QByteArray xmlQuery = QString(
                                  "<C:calendar-query xmlns:C=\"urn:ietf:params:xml:ns:caldav\" xmlns:D=\"DAV\">"
                                  "  <ns0:prop xmlns:ns0=\"DAV:\"><C:calendar-data><C:expand start=\"%1Z\" end=\"%2Z\"/></C:calendar-data></ns0:prop>"
                                  "  <C:filter>"
                                  "    <C:comp-filter name=\"VCALENDAR\">"
                                  "      <C:comp-filter name=\"VEVENT\">"
                                  "        <C:time-range start=\"%1Z\" end=\"%2Z\"/>"
                                  "      </C:comp-filter>"
                                  "    </C:comp-filter>"
                                  "  </C:filter>"
                                  "</C:calendar-query>").arg(start, end).toUtf8();

        //qInfo() << xmlQuery;

        QNetworkReply *reply = manager->sendCustomRequest(request, "REPORT", xmlQuery);

        connect(reply, &QNetworkReply::finished, [this, reply, calId]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray jsonEvents = parseEvents(calId, reply->readAll());

                //std::string rawCalDavData = fetchFromCalDav(); // Your network logic here
                //QList<CalendarEvent> calendarEvents = IcsParser::parseIcs(reply->readAll().toStdString());

                //for (const auto& e : calendarEvents) {
                //    qDebug() << "Event:" << e.summary << "Starts at:" << e.start.toString();
                //}

                emit eventsLoaded(jsonEvents.toVariantList(), calId);
            }
            reply->deleteLater();
        });
    }

    Q_INVOKABLE void fetchCalendars(const QString &url, const QString &user, const QString &pass) {
        QNetworkAccessManager *manager = new QNetworkAccessManager(this);

        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/xml; charset=utf-8");
        request.setRawHeader("Depth", "1");

        // Basic Auth
        QString auth = QString("%1:%2").arg(user).arg(pass).toLocal8Bit().toBase64();
        request.setRawHeader("Authorization", "Basic " + auth.toLocal8Bit());

        // CalDAV REPORT query for a time range
        QByteArray xmlQuery = QString(
                                  "<D:propfind xmlns:D=\"DAV:\" xmlns:apple=\"http://apple.com/ns/ical/\"><D:prop><D:current-user-privilege-set/><D:displayname/><D:resourcetype/><apple:calendar-color /></D:prop></D:propfind>").toUtf8();

        QNetworkReply *reply = manager->sendCustomRequest(request, "PROPFIND", xmlQuery);

        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray jsonCalendars = parseCalendars(reply->readAll());
                emit calendarsLoaded(jsonCalendars.toVariantList());
            }
            reply->deleteLater();
        });
    }

signals:
    void calendarsLoaded(QVariantList calendars);
    void eventsLoaded(QVariantList events, int calId);

private:

    QJsonArray parseCalendars(const QByteArray &xmlData) {
        QJsonArray calendarsArray;

        QXmlStreamReader reader(xmlData);

        int curCal = 0;
        while (!reader.atEnd()) {
            QXmlStreamReader::TokenType token = reader.readNext();
            if(token == QXmlStreamReader::StartElement && reader.name() == "response") {
                QJsonObject response;
                bool shouldSkip = true;
                token = reader.readNext();
                while (reader.name() != "response") {
                    if (token == QXmlStreamReader::EndElement) { //ignore all end elements
                        token = reader.readNext();
                        continue;
                    }

                    if (reader.name() == "href") {
                        response["href"] = reader.readElementText();
                    } else if (reader.name() == "displayname") {
                        response["displayname"] = reader.readElementText();
                    } else if (reader.name() == "calendar-color") {
                        response["calendarcolor"] = reader.readElementText();
                    } else if (reader.name() == "resourcetype") {
                        //we don't actually care about resourcetype - we just want to know if it's a calendar or not
                        token = reader.readNext();
                        bool isCalendar = false;
                        while (reader.name() != "resourcetype") {
                            if (reader.name() == "calendar")
                                shouldSkip = false;
                            token = reader.readNext();
                        }
                    } else if (reader.name() == "current-user-privilege-set") {
                        token = reader.readNext();
                        QJsonArray privileges;
                        while (reader.name() != "current-user-privilege-set") {
                            if (reader.name() != "privilege")
                                privileges.append(reader.name().toString());
                            token = reader.readNext();
                        }
                        response["privileges"] = privileges;
                    } else {
                    }
                    token = reader.readNext();
                }
                if (!shouldSkip) {
                    response["id"] = curCal;
                    calendarsArray.append(response);
                    curCal++;
                }
            }
        }

        if (reader.hasError()) {
            qWarning() << "XML Parsing Error:" << reader.errorString();
        }

        return calendarsArray;
    }

    QJsonArray parseEvents(const int &calId, const QByteArray &xmlData) {
        QJsonArray eventsArray;
        QXmlStreamReader reader(xmlData);

        while (!reader.atEnd() && !reader.hasError()) {
            QXmlStreamReader::TokenType token = reader.readNext();

            if (token == QXmlStreamReader::StartElement) {
                QString name = reader.name().toString();

                // Extract Event Data
                if (name == "calendar-data") {
                    QString icsData = reader.readElementText();

                    QList<CalendarEvent> calendarEvents = IcsParser::parseIcs(icsData.toStdString());

                    for (int i = 0; i < calendarEvents.length(); i++) {
                        //qInfo() << calendarEvents[i].summary << "@" << calendarEvents[i].start.toString();
                        QJsonObject eventObj;
                        eventObj.insert("start", calendarEvents[i].start.toMSecsSinceEpoch());
                        eventObj.insert("end", calendarEvents[i].end.toMSecsSinceEpoch());
                        eventObj.insert("allDay", calendarEvents[i].allDay);
                        eventObj.insert("summary", calendarEvents[i].summary);
                        eventObj.insert("uid", calendarEvents[i].uid);
                        eventObj.insert("calId", calId);
                        eventsArray.append(eventObj);
                    }
                }
            }
        }

        if (reader.hasError()) {
            qWarning() << "XML Parsing Error:" << reader.errorString();
        }

        return eventsArray;
    }

};

#endif // CALENDARMANAGER_H
