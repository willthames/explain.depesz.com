BEGIN;
SET search_path = public, pg_catalog;

DROP VIEW IF EXISTS public.time_for_10000;
DROP VIEW IF EXISTS public.namespace_usage;
DROP VIEW IF EXISTS public.growth_estimate;
DROP VIEW IF EXISTS public.by_month;

CREATE VIEW by_month AS
 WITH sums_by_month AS (
         SELECT to_char(plans.entered_on, 'YYYY-MM'::text) AS month,
            count(*) AS "all",
            count(NULLIF(plans.is_public, false)) AS public,
            count(NULLIF(plans.is_public, true)) AS private,
            count(NULLIF(plans.is_anonymized, false)) AS anonymized,
            count(NULLIF(plans.is_deleted, false)) AS deleted,
            (((count(*))::double precision / (count(DISTINCT (plans.entered_on)::date))::double precision))::numeric(10,1) AS avg_per_day
           FROM plans
          GROUP BY (to_char(plans.entered_on, 'YYYY-MM'::text))
        )
 SELECT sums_by_month.month,
    sums_by_month."all",
    sums_by_month.public,
    sums_by_month.private,
    sums_by_month.anonymized,
    sums_by_month.avg_per_day,
    sum(sums_by_month."all") OVER (ORDER BY sums_by_month.month) AS total,
    sum(sums_by_month.public) OVER (ORDER BY sums_by_month.month) AS total_public,
    sum(sums_by_month.private) OVER (ORDER BY sums_by_month.month) AS total_private,
    sum(sums_by_month.anonymized) OVER (ORDER BY sums_by_month.month) AS total_anonymized,
    sum(sums_by_month.deleted) OVER (ORDER BY sums_by_month.month) AS total_deleted
   FROM sums_by_month
  ORDER BY sums_by_month.month;

CREATE VIEW growth_estimate AS
 WITH base_info AS (
         SELECT count(*) AS all_count,
            count(*) FILTER (WHERE (plans.entered_on > (now() - '7 days'::interval))) AS count_7d,
            count(*) FILTER (WHERE (plans.entered_on > (now() - '30 days'::interval))) AS count_30d,
            count(*) FILTER (WHERE (plans.entered_on > (now() - '365 days'::interval))) AS count_365d,
            floor(log((count(*))::double precision)) AS all_count_log
           FROM plans
        ), with_targets AS (
         SELECT base_info.all_count,
            base_info.count_7d,
            base_info.count_30d,
            base_info.count_365d,
            base_info.all_count_log,
            ((10)::double precision ^ ((1)::double precision + base_info.all_count_log)) AS target_high,
            (((1)::double precision + floor(((base_info.all_count)::double precision / ((10)::double precision ^ base_info.all_count_log)))) * ((10)::double precision ^ base_info.all_count_log)) AS target_low
           FROM base_info
        )
 SELECT with_targets.target_low AS target,
    date_part('day'::text, (((with_targets.target_low - (with_targets.all_count)::double precision) / (with_targets.count_7d)::double precision) * '7 days'::interval)) AS estimate_7d,
    ((now() + (((with_targets.target_low - (with_targets.all_count)::double precision) / (with_targets.count_7d)::double precision) * '7 days'::interval)))::timestamp(0) with time zone AS eta_7d,
    date_part('day'::text, (((with_targets.target_low - (with_targets.all_count)::double precision) / (with_targets.count_30d)::double precision) * '30 days'::interval)) AS estimate_30d,
    ((now() + (((with_targets.target_low - (with_targets.all_count)::double precision) / (with_targets.count_30d)::double precision) * '30 days'::interval)))::timestamp(0) with time zone AS eta_30d,
    date_part('day'::text, (((with_targets.target_low - (with_targets.all_count)::double precision) / (with_targets.count_365d)::double precision) * '365 days'::interval)) AS estimate_365d,
    ((now() + (((with_targets.target_low - (with_targets.all_count)::double precision) / (with_targets.count_365d)::double precision) * '365 days'::interval)))::timestamp(0) with time zone AS eta_365d
   FROM with_targets
UNION ALL
 SELECT with_targets.target_high AS target,
    date_part('day'::text, (((with_targets.target_high - (with_targets.all_count)::double precision) / (with_targets.count_7d)::double precision) * '7 days'::interval)) AS estimate_7d,
    ((now() + (((with_targets.target_high - (with_targets.all_count)::double precision) / (with_targets.count_7d)::double precision) * '7 days'::interval)))::timestamp(0) with time zone AS eta_7d,
    date_part('day'::text, (((with_targets.target_high - (with_targets.all_count)::double precision) / (with_targets.count_30d)::double precision) * '30 days'::interval)) AS estimate_30d,
    ((now() + (((with_targets.target_high - (with_targets.all_count)::double precision) / (with_targets.count_30d)::double precision) * '30 days'::interval)))::timestamp(0) with time zone AS eta_30d,
    date_part('day'::text, (((with_targets.target_high - (with_targets.all_count)::double precision) / (with_targets.count_365d)::double precision) * '365 days'::interval)) AS estimate_365d,
    ((now() + (((with_targets.target_high - (with_targets.all_count)::double precision) / (with_targets.count_365d)::double precision) * '365 days'::interval)))::timestamp(0) with time zone AS eta_365d
   FROM with_targets;

CREATE VIEW namespace_usage AS
 SELECT length(plans.id) AS length,
    count(*) AS count,
    ((((100 * count(*)))::double precision / ((62)::double precision ^ (length(plans.id))::double precision)))::numeric(12,9) AS filled_percent,
    ((62)::double precision ^ (length(plans.id))::double precision) AS namespace_size
   FROM plans
  GROUP BY (length(plans.id))
  ORDER BY (length(plans.id));

CREATE VIEW time_for_10000 AS
 WITH numbered AS (
         SELECT plans.entered_on,
            row_number() OVER (ORDER BY plans.entered_on) - 1 AS number,
            ( (row_number() OVER (ORDER BY plans.entered_on) - 1 ) / 10000) AS range_number
           FROM plans
        ), times AS (
         SELECT format('%s - %s'::text, min(numbered.number) + 1, max(numbered.number) + 1) AS range,
            (max(numbered.entered_on) - min(numbered.entered_on)) AS time_for_10000,
            count(*) as plan_count,
            numbered.range_number
           FROM numbered
          GROUP BY numbered.range_number
        )
 SELECT times.range,
    times.time_for_10000,
    times.plan_count,
    (((100)::double precision * (date_part('epoch'::text, times.time_for_10000) / date_part('epoch'::text, lag(times.time_for_10000) OVER (ORDER BY times.range_number)))))::numeric(5,2) AS percent_of_previous_10k
   FROM times
  ORDER BY times.range_number;
COMMIT;
