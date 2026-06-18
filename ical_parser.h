#ifndef ICAL_PARSER_H
#define ICAL_PARSER_H

#include <libical/ical.h>
#include <QDateTime>
#include <QTimeZone>
#include <QList>
#include <QString>
#include <QDebug>

struct CalendarEvent {
    QString summary;
    QDateTime start;
    QDateTime end;
    QString uid;
    bool allDay;
};

class IcsParser {
public:
    static QList<CalendarEvent> parseIcs(const std::string& icsData) {
        QList<CalendarEvent> events;

        // 1. Parse the string into an icalcomponent
        icalcomponent* root = icalparser_parse_string(icsData.c_str());
        if (!root) return events;

        // 1. Create a container for the timezone
        icaltimezone* userTz = nullptr;

        // 2. Extract the VTIMEZONE
        icalcomponent* vtz = icalcomponent_get_first_component(root, ICAL_VTIMEZONE_COMPONENT);
        if (vtz) {
            userTz = icaltimezone_new();
            if (!icaltimezone_set_component(userTz, vtz)) {
                qInfo() << "failed to set";
                // If it fails to set, clean up
                icaltimezone_free(userTz, 1);
                userTz = nullptr;
            }
        }

        // 3. Iterate through VEVENT components
        icalcomponent* comp;
        for (comp = icalcomponent_get_first_component(root, ICAL_VEVENT_COMPONENT);
             comp != nullptr;
             comp = icalcomponent_get_next_component(root, ICAL_VEVENT_COMPONENT)) {

            events.append(parseEvent(comp, userTz));
        }

        icalcomponent_free(root);
        return events;
    }

private:
    static CalendarEvent parseEvent(icalcomponent* comp, icaltimezone* userTz) {
        CalendarEvent event;

        // Get Summary
        icalproperty* prop = icalcomponent_get_first_property(comp, ICAL_SUMMARY_PROPERTY);
        if (prop) event.summary = QString::fromUtf8(icalproperty_get_summary(prop));

        // Get UID
        prop = icalcomponent_get_first_property(comp, ICAL_UID_PROPERTY);
        if (prop) event.uid = QString::fromUtf8(icalproperty_get_uid(prop));

        icaltimetype _st = icalcomponent_get_dtstart(comp);
        icaltimetype _en = icalcomponent_get_dtend(comp);
        event.allDay = _st.is_date ? true : false;

        if (_st.is_date) {
            //all day events are floating local and don't need converting to local timezone
            //QDateTime dt(QDate(_st.year, _st.month, _st.day), QTime(0, 0), Qt::LocalTime);
            QDateTime dt(QDate(_st.year, _st.month, _st.day), QTime(0, 0), QTimeZone::LocalTime);
            event.start = dt;

            //QDateTime edt(QDate(_en.year, _en.month, _en.day), QTime(0, 0), Qt::LocalTime);
            QDateTime edt(QDate(_en.year, _en.month, _en.day), QTime(0, 0), QTimeZone::LocalTime);
            event.end = edt;
        } else {
            event.start = icalTimeToQDateTime(_st, userTz);
            event.end = icalTimeToQDateTime(_en, userTz);
        }

        return event;
    }

    static QDateTime icalTimeToQDateTime(struct icaltimetype t, icaltimezone* fallbackTz) {
        if (icaltime_is_utc(t)) {
            //return QDateTime::fromSecsSinceEpoch(icaltime_as_timet(t), Qt::UTC).toLocalTime();
            return QDateTime::fromSecsSinceEpoch(icaltime_as_timet(t), QTimeZone::fromSecondsAheadOfUtc(0));
        }
        // Try to get the zone from the time object itself first
        const icaltimezone* zone = t.zone;

        // If libical didn't automatically link the zone, use our parsed fallback
        if (!zone) {
            zone = fallbackTz;
        }

        // If we still have no zone, default to UTC to avoid a crash
        if (!zone) {
            zone = icaltimezone_get_utc_timezone();
        }

        time_t epoch = icaltime_as_timet_with_zone(t, zone);
        //return QDateTime::fromSecsSinceEpoch(epoch, Qt::LocalTime);
        return QDateTime::fromSecsSinceEpoch(epoch, QTimeZone::fromSecondsAheadOfUtc(0));
    }
};

#endif // ICAL_PARSER_H
