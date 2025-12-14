# P11 - DAST (ZAP baseline)

**Target:** http://localhost:8000/

**Reports:** EVIDENCE/P11/zap_baseline.html, zap_baseline.json

## Результаты сканирования

**Result:** 1 alert (High=0, Medium=0, Low=1)

### Findings

**Low:**
- **X-Content-Type-Options Header Missing** (CWE-693)
  - **Описание:** Отсутствует заголовок X-Content-Type-Options, что позволяет старым версиям браузеров выполнять MIME-sniffing
  - **Решение:** Добавлен middleware для установки заголовка `X-Content-Type-Options: nosniff` во всех ответах
  - **Статус:** ✅ Исправлено

## План действий

- [x] Исправлена проблема с отсутствующим заголовком X-Content-Type-Options
- [ ] После повторного запуска ZAP проверить, что предупреждение исчезло

## Изменения

1. Добавлен `SecurityHeadersMiddleware` в `app/main.py` для установки заголовка `X-Content-Type-Options: nosniff`
2. Workflow настроен для запуска ZAP baseline scan через API

## Примечания

- Все остальные проверки ZAP прошли успешно (PASS)
- Найдено только одно предупреждение низкого уровня, которое было исправлено
- После merge и повторного запуска workflow предупреждение должно исчезнуть
