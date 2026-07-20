-- One-off cleanup: remove the panic-alert rows Claude created while verifying
-- the buzzer + guard-remarks features (they clutter the admin Alert History).
-- Run in the PHH project SQL editor. Safe: only touches the test rows.
DELETE FROM public.emergencies
WHERE subtitle LIKE '%TEST buzzer%'
   OR subtitle LIKE '%REMARKS-DEMO%';
