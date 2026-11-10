// Russian (ru) server texts. Same keys and placeholders as ka.ts.
// Phrasing avoids numeral/case agreement with inserted values
// (e.g. "осталось дней: {days}", "с командой «{opponent}»").
import type { Catalog } from './ka';

export const MESSAGES_RU: Catalog = {
  sms: {
    d5: 'Напоминание: оплата за {sport} ({child}) — {amount} ₾ до {date}.',
    d1: 'Напоминание: завтра, {date}, последний день оплаты за {sport} ({child}) — {amount} ₾.',
    d5Multi: 'Напоминание: оплата за {children} — {amount} ₾ до {date}.',
    d1Multi: 'Напоминание: завтра, {date}, последний день оплаты за {children} — {amount} ₾.',
    invite: '{group}: приглашение для {child}. Зарегистрируйтесь в приложении с этим номером.',
  },
  push: {
    newTraining: { title: 'Новая тренировка', body: '{group}: {date}, {time}' },
    trainingCancelled: { title: 'Тренировка отменена', body: '{group}: {date}, {time}' },
    trainingMoved: { title: 'Тренировка перенесена', body: '{group}: новое время {date}, {time}' },
    trainingReminder: { title: 'Тренировка через 2 часа', body: '{group}: сегодня в {time}' },
    newPhotos: { title: 'Новые фото', body: '{group}: новых фото — {count}' },
    chatMessage: { title: '{sender} · {group}', body: '{text}' },
    certificateExpiring: { title: 'Срок справки истекает', body: '{child}: срок действия медицинской справки истекает {date} (осталось дней: {days}).' },
    certificateExpired: { title: 'Срок справки истёк', body: '{child}: срок действия медицинской справки истёк. Загрузите новую справку.' },
    paymentReminder: { title: 'Напоминание об оплате', body: '{text}' },
    trainingCancelledReason: { title: 'Тренировка отменена', body: '{group}: {date}, {time}. Причина: {reason}' },
    newMatch: { title: 'Новый матч', body: '{group}: {opponent}, {date}, {time}' },
    matchCancelled: { title: 'Матч отменён', body: '{group}: {opponent}, {date}. Причина: {reason}' },
    matchMoved: { title: 'Матч перенесён', body: '{group}: {opponent}, новое время {date}, {time}' },
    matchReminder1d: { title: 'Завтра матч', body: '{group}: {opponent}, {date}, {time}' },
    matchReminder2h: { title: 'Матч через 2 часа', body: '{group}: {opponent}, сегодня в {time}' },
    groupInvite: { title: 'Приглашение в группу', body: '{group}: {child}' },
    inviteAnswered: { title: 'Ответ на приглашение', body: '{child}: приглашение {answer}' },
    scheduleChanged: { title: 'Расписание обновлено', body: '{group}: {summary}' },
    announcement: { title: 'Объявление · {group}', body: '{text}' },
    newMedia: { title: 'Новые материалы', body: '{group}: новых файлов — {count}' },
    certificateExpiresToday: { title: 'Срок справки истекает сегодня', body: '{child}: срок действия медицинской справки истекает сегодня ({date}). Загрузите новую справку.' },
    paymentProofSubmitted: { title: 'Подтверждение оплаты на проверку', body: '{group}: {child} — {amount} ₾, оплачено {date}' },
    paymentProofApproved: { title: 'Оплата подтверждена', body: '{child}: {amount} ₾ — оплата подтверждена.' },
    paymentProofRejected: { title: 'Оплата не подтверждена', body: '{child}: {amount} ₾. Причина: {reason}' },
    trainingPlanPublished: { title: 'Новый план тренировок', body: '{group}: {title}' },
  },
  system: {
    trainingCancelled: 'Тренировка {date} в {time} отменена. Причина: {reason}',
    matchCancelled: 'Матч с командой «{opponent}» ({date}, {time}) отменён. Причина: {reason}',
    newMatch: 'Новый матч: {opponent} — {date}, {time}',
    matchMoved: 'Матч с командой «{opponent}» перенесён: {date}, {time}',
  },
  words: {
    inviteAccepted: 'принято',
    inviteDeclined: 'отклонено',
    seriesEnded: 'серия завершена',
  },
  cancelReasons: {
    illness: 'Болезнь',
    weather: 'Погода',
    venueBusy: 'Площадка занята',
    other: 'Другое',
  },
  weekdays: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
};
