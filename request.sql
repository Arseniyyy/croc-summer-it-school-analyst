WITH ОтчетПоМесяцам AS (
    SELECT
        DATE_TRUNC('month', с."IssueDate") AS Месяц,
        к."ClientId",
        к."Name" AS Клиент,
        с."InvoiceId",
        с."Amount" AS СуммаПредоплаты,
        с."DueDate" AS СрокОплаты,
        COALESCE(
            SUM(о."Amount") FILTER (WHERE о."PaymentDate" <= с."DueDate"),
            0
        ) AS ОплаченоВовремя,
        (с."Amount" - COALESCE(
            SUM(о."Amount") FILTER (WHERE о."PaymentDate" <= с."DueDate"),
            0
        )) AS НевнесеннаяСумма
    FROM "Счёт" с
    JOIN "Заявка" з ON с."RequestId" = з."RequestId"
    JOIN "Клиент" к ON з."ClientId" = к."ClientId"
    LEFT JOIN "Оплата" о ON о."InvoiceId" = с."InvoiceId"
    WHERE с."IsPrepayment" = true
      AND DATE_TRUNC('month', с."IssueDate") IN (
            DATE_TRUNC('month', CURRENT_DATE),
            DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
      )
    GROUP BY
        DATE_TRUNC('month', с."IssueDate"),
        к."ClientId",
        к."Name",
        с."InvoiceId",
        с."Amount",
        с."DueDate"
    HAVING (с."Amount" - COALESCE(SUM(о."Amount") FILTER (WHERE о."PaymentDate" <= с."DueDate"), 0)) > 0
)

SELECT
    CASE
        WHEN Месяц = DATE_TRUNC('month', CURRENT_DATE)
            THEN 'Текущий месяц'
        ELSE 'Предыдущий месяц'
    END AS Период,
    COUNT(DISTINCT "ClientId") AS Количество_клиентов_не_оплативших_предоплату,
    SUM("НевнесеннаяСумма") AS Общая_сумма_невнесенной_предоплаты,
    ROUND(
        AVG("НевнесеннаяСумма"), 2
    ) AS Средняя_сумма_на_одного_клиента
FROM ОтчетПоМесяцам
GROUP BY Месяц
ORDER BY Месяц DESC;
