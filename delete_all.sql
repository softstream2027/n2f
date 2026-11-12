-- =====================================================================
-- NETTOYAGE DE LA BASE AXELOR : version finale
-- Conserve : l'utilisateur admin (et son tiers / employé), la société Axelor
--            (et son tiers), et le compte technique du SaaS backend.
-- Lancer avec :  docker compose exec -T db psql -U sbsoft2026 -d sbsoft2026 -v ON_ERROR_STOP=1 < cleanup_axelor.sql
-- Tout est dans UNE transaction : à la moindre erreur ou vérification qui échoue, RIEN n'est modifié.
-- Pour un essai à blanc, remplacez le COMMIT final par ROLLBACK.
-- =====================================================================
BEGIN;

-- ---------------------------------------------------------------------
-- 0. CE QU'ON CONSERVE (calculé AVANT toute suppression)
-- ---------------------------------------------------------------------
-- ⚠ Mettez ici le login du compte technique utilisé par le backend (AXELOR_USERNAME)
CREATE TEMP TABLE keep_users ON COMMIT DROP AS
  SELECT id FROM auth_user WHERE code IN ('admin', 'saas-provisioner');

CREATE TEMP TABLE keep_companies ON COMMIT DROP AS
  SELECT id FROM base_company
  WHERE name = 'Axelor'
     OR id IN (SELECT active_company FROM auth_user WHERE id IN (SELECT id FROM keep_users) AND active_company IS NOT NULL);

CREATE TEMP TABLE keep_partners ON COMMIT DROP AS
  SELECT id FROM base_partner
  WHERE name = 'Axelor'
     OR id IN (SELECT partner FROM auth_user WHERE id IN (SELECT id FROM keep_users) AND partner IS NOT NULL)
     OR id IN (SELECT partner FROM base_company WHERE id IN (SELECT id FROM keep_companies) AND partner IS NOT NULL);

CREATE TEMP TABLE keep_employees ON COMMIT DROP AS
  SELECT employee AS id FROM auth_user WHERE id IN (SELECT id FROM keep_users) AND employee IS NOT NULL;

-- Désactivation temporaire des clés étrangères pour le nettoyage massif
SET session_replication_role = 'replica';

-- ---------------------------------------------------------------------
-- 1. PRODUITS / VARIANTES
-- ---------------------------------------------------------------------
DELETE FROM account_tax_line WHERE end_date IS NOT NULL;
UPDATE base_product SET default_supplier_partner = NULL;

DELETE FROM base_product_variant_config_product_variant_value1set;
DELETE FROM base_product_variant_config_product_variant_value2set;
DELETE FROM base_product_variant_config;
DELETE FROM base_product_variant;
DELETE FROM base_product_variant_value;

DELETE FROM supplychain_mrp_product_set;
DELETE FROM account_reconcile_payment_move_line_distribution_list;
DELETE FROM account_payment_move_line_distribution;

-- ---------------------------------------------------------------------
-- 2. COMPTABILITÉ (factures, écritures, paiements)
-- ---------------------------------------------------------------------
DELETE FROM account_pay_voucher_due_element;
DELETE FROM account_pay_voucher_element_to_pay;
UPDATE account_move SET payment_voucher = NULL;
DELETE FROM account_payment_voucher;

DELETE FROM account_invoice_line_tax_line_set;
DELETE FROM account_invoice_line;
DELETE FROM account_invoice_term_payment_reconcile_list;
DELETE FROM account_invoice_term_payment;
DELETE FROM account_invoice_term;
DELETE FROM account_invoice_line_tax;

UPDATE account_invoice SET move = NULL;
DELETE FROM account_move_line;
DELETE FROM account_invoice_payment;
DELETE FROM account_move;
DELETE FROM account_invoice_stock_move_set;

-- ---------------------------------------------------------------------
-- 3. PRODUCTION / PROJETS / TEMPS
-- ---------------------------------------------------------------------
DELETE FROM production_temp_bom_tree;
DELETE FROM project_project_task_tag_set;
DELETE FROM hr_timesheet_line;
DELETE FROM project_project_check_list_item;
DELETE FROM project_project_task_timer_list;
DELETE FROM project_project_planning_time;
DELETE FROM project_project_task;

-- ---------------------------------------------------------------------
-- 4. VENTES, ACHATS, STOCK
-- ---------------------------------------------------------------------
DELETE FROM stock_inventory_line;
DELETE FROM stock_stock_location_line_history;
DELETE FROM stock_stock_location_line;
UPDATE stock_stock_move_line SET tracking_number = NULL;
DELETE FROM stock_tracking_number;

DELETE FROM stock_stock_move_line;
DELETE FROM production_cost_sheet_line;
DELETE FROM production_cost_sheet;
DELETE FROM production_manuf_order_production_order_set;
DELETE FROM production_manuf_order_sale_order_set;
DELETE FROM production_operation_order_duration;
DELETE FROM production_operation_order;
DELETE FROM production_prod_product;

DELETE FROM stock_stock_move_purchase_order_set;
DELETE FROM stock_stock_move_sale_order_set;
DELETE FROM stock_stock_move;

DELETE FROM production_manuf_order;
DELETE FROM quality_qi_identification_sourceqilist;
DELETE FROM quality_quality_improvement;
DELETE FROM quality_qi_identification;
DELETE FROM sale_complementary_product_selected;
DELETE FROM sale_sale_order_line;
DELETE FROM sale_sale_order_line_tax;
DELETE FROM production_production_order;

DELETE FROM sale_sale_order;
DELETE FROM purchase_purchase_order_line_tax_line_set;
DELETE FROM purchase_purchase_order_line;
DELETE FROM purchase_purchase_order_line_tax;
DELETE FROM purchase_purchase_order;

-- ---------------------------------------------------------------------
-- 5. NOMENCLATURES (BOM) ET PROCESSUS
-- ---------------------------------------------------------------------
UPDATE base_product SET default_bill_of_material = NULL;
DELETE FROM production_bill_of_material_line;
DELETE FROM production_bill_of_material WHERE name != 'STD';
DELETE FROM production_object_description;
DELETE FROM production_prod_process_line;
DELETE FROM production_prod_process WHERE name != 'STD';
DELETE FROM supplychain_supplychain_batch_used_stock_rules_set;
DELETE FROM stock_stock_rules;
DELETE FROM supplychain_mrp_forecast;
DELETE FROM purchase_supplier_catalog;
DELETE FROM sale_complementary_product;
DELETE FROM bankpayment_bank_statement_rule;
DELETE FROM stock_inventory;
DELETE FROM intervention_equipment_line;
DELETE FROM stock_freight_carrier_mode;
DELETE FROM account_move_template_line;
DELETE FROM project_project_project_task_category_set;
DELETE FROM project_project_task_category_project_task_status_set;
DELETE FROM project_task_status_progress_by_category;
DELETE FROM project_project_task_category;
DELETE FROM base_alternative_barcode;
DELETE FROM stock_logistical_form;
DELETE FROM bankpayment_bank_statement_line_afb120;

-- ---------------------------------------------------------------------
-- 6. BANQUE ET LIAISONS DES TIERS (tout sauf les tiers conservés)
-- ---------------------------------------------------------------------
DELETE FROM bankpayment_bank_order_line_origin;
DELETE FROM bankpayment_bank_order_line;
DELETE FROM base_bank_details WHERE partner NOT IN (SELECT id FROM keep_partners);
DELETE FROM base_blocking_company_set;
DELETE FROM base_blocking WHERE partner NOT IN (SELECT id FROM keep_partners);
DELETE FROM base_partner_address WHERE partner NOT IN (SELECT id FROM keep_partners);
DELETE FROM base_partner_company_set WHERE base_partner NOT IN (SELECT id FROM keep_partners);
DELETE FROM base_partner_contact_partner_set WHERE base_partner NOT IN (SELECT id FROM keep_partners);

-- ---------------------------------------------------------------------
-- 7. CRM / ÉVÉNEMENTS / RH
-- ---------------------------------------------------------------------
DELETE FROM ical_user;
DELETE FROM crm_event_reminder;
DELETE FROM ical_event;
DELETE FROM crm_opportunity;
DELETE FROM hr_extra_hours_line;
DELETE FROM project_project_members_user_set;
DELETE FROM project_project_project_task_priority_set;
DELETE FROM project_project_project_task_status_set;
DELETE FROM project_project;
DELETE FROM quality_qi_resolution_decision;
DELETE FROM stock_partner_stock_settings;
DELETE FROM ical_event_qi_resolution_defaults_set;
DELETE FROM hr_leave_request;
DELETE FROM base_trace_back;

-- Utilisateurs : on détache puis on supprime tous sauf admin et le compte technique
UPDATE auth_user SET partner = NULL, employee = NULL WHERE id NOT IN (SELECT id FROM keep_users);
DELETE FROM auth_user_company_set WHERE auth_user NOT IN (SELECT id FROM keep_users);
DELETE FROM auth_user WHERE id NOT IN (SELECT id FROM keep_users);

DELETE FROM team_team_members WHERE members NOT IN (SELECT id FROM keep_users);
DELETE FROM quality_qi_analysis_cause_qi_resolution_defaults_set;
DELETE FROM quality_qi_analysis_cause;
DELETE FROM sale_configurator_creator_authorized_user_set WHERE authorized_user_set NOT IN (SELECT id FROM keep_users);
DELETE FROM quality_qi_analysis;
DELETE FROM intervention_customer_request_equipment_set;
DELETE FROM intervention_intervention_equipment_set;
DELETE FROM intervention_intervention;
DELETE FROM intervention_customer_request;
DELETE FROM quality_qi_process;

DELETE FROM crm_lead;
DELETE FROM fleet_vehicle_fuel_log;
DELETE FROM fleet_vehicle_contract;
DELETE FROM fleet_vehicle;
DELETE FROM intervention_equipment;

UPDATE hr_employment_contract SET employee = NULL WHERE NOT EXISTS (
  SELECT 1 FROM hr_employee e
  WHERE e.id IN (SELECT id FROM keep_employees) AND e.main_employment_contract = hr_employment_contract.id
);
DELETE FROM hr_leave_management;
DELETE FROM hr_leave_line;
DELETE FROM hr_timesheet;
DELETE FROM hr_lunch_voucher_mgt_line;

DELETE FROM helpdesk_ticket;
DELETE FROM hr_payroll_preparation_other_costs_employee_set;
DELETE FROM hr_payroll_preparation;

-- Contrat principal : on garde uniquement celui des employés conservés
UPDATE hr_employee SET main_employment_contract = NULL WHERE id NOT IN (SELECT id FROM keep_employees);
DELETE FROM hr_employment_contract WHERE NOT EXISTS (
  SELECT 1 FROM hr_employee e
  WHERE e.id IN (SELECT id FROM keep_employees) AND e.main_employment_contract = hr_employment_contract.id
);

DELETE FROM sale_cart_line;
DELETE FROM stock_stock_correction;
DELETE FROM base_import_history;

-- ---------------------------------------------------------------------
-- 8. PRODUITS, EMPLOYÉS (on garde les articles NDF-% et ceux des notes de frais)
-- ---------------------------------------------------------------------
DELETE FROM base_product
WHERE code NOT LIKE 'NDF-%'
  AND id NOT IN (SELECT product FROM hr_expense_line WHERE product IS NOT NULL);

DELETE FROM hr_employee_batch_set;
DELETE FROM hr_employee WHERE id NOT IN (SELECT id FROM keep_employees);

DELETE FROM base_pricing_line;
DELETE FROM base_pricing;
DELETE FROM account_accounting_situation;
DELETE FROM account_accounting_report_partner_set;

UPDATE ical_user SET event = NULL;
DELETE FROM ical_event;
DELETE FROM ical_user;
DELETE FROM crm_opportunity;
DELETE FROM supplychain_mrp_line_origin;
DELETE FROM supplychain_mrp_line;

DELETE FROM project_wiki;
DELETE FROM project_project;
DELETE FROM account_payment_session_partner_set;

-- Prix des produits (les NDF ne sont pas modifiés)
UPDATE base_product SET manag_price_coef = 1.35, purchase_price = sale_price / 1.35
WHERE code NOT LIKE 'NDF-%';

-- ---------------------------------------------------------------------
-- 9. SOCIÉTÉS ET TIERS : on garde Axelor, admin et le compte technique
-- ---------------------------------------------------------------------
DELETE FROM base_company WHERE id NOT IN (SELECT id FROM keep_companies);
DELETE FROM base_partner WHERE id NOT IN (SELECT id FROM keep_partners);

DELETE FROM account_account_default_tax_set
  WHERE account_account IN (SELECT id FROM account_account WHERE company NOT IN (SELECT id FROM keep_companies));
DELETE FROM account_account_management_sale_tax_set
  WHERE account_account_management IN (SELECT id FROM account_account_management WHERE company NOT IN (SELECT id FROM keep_companies));
DELETE FROM account_account_management_purchase_tax_set
  WHERE account_account_management IN (SELECT id FROM account_account_management WHERE company NOT IN (SELECT id FROM keep_companies));
DELETE FROM account_account_management WHERE company NOT IN (SELECT id FROM keep_companies);

DELETE FROM account_account_config_move_on_temp_closure_authorized_role_lis
  WHERE account_account_config IN (SELECT id FROM account_account_config WHERE company NOT IN (SELECT id FROM keep_companies));
DELETE FROM account_account_config_closure_authorized_role_list
  WHERE account_account_config IN (SELECT id FROM account_account_config WHERE company NOT IN (SELECT id FROM keep_companies));
DELETE FROM account_account_config_clearance_account_set
  WHERE account_account_config IN (SELECT id FROM account_account_config WHERE company NOT IN (SELECT id FROM keep_companies));
DELETE FROM account_invoice_product_statement
  WHERE account_config IN (SELECT id FROM account_account_config WHERE company NOT IN (SELECT id FROM keep_companies));
DELETE FROM account_account_config_temporary_closure_authorized_role_list
  WHERE account_account_config IN (SELECT id FROM account_account_config WHERE company NOT IN (SELECT id FROM keep_companies));
DELETE FROM account_account_config WHERE company NOT IN (SELECT id FROM keep_companies);

DELETE FROM account_journal_valid_account_set
  WHERE valid_account_set IN (SELECT id FROM account_account WHERE company NOT IN (SELECT id FROM keep_companies));
DELETE FROM account_account_equiv
  WHERE from_account IN (SELECT id FROM account_account WHERE company NOT IN (SELECT id FROM keep_companies));
DELETE FROM account_account_equiv
  WHERE to_account IN (SELECT id FROM account_account WHERE company NOT IN (SELECT id FROM keep_companies));
DELETE FROM account_account_compatible_account_set
  WHERE compatible_account_set IN (SELECT id FROM account_account WHERE company NOT IN (SELECT id FROM keep_companies));
DELETE FROM account_account WHERE company NOT IN (SELECT id FROM keep_companies);

-- ---------------------------------------------------------------------
-- 10. RÉPARATION DES RÉFÉRENCES ORPHELINES (clé étrangère simple)
--     colonne facultative -> mise à NULL ; colonne obligatoire -> ligne supprimée
-- ---------------------------------------------------------------------
DO $$
DECLARE r record; n bigint; pass int := 0; total bigint;
BEGIN
  LOOP
    pass := pass + 1; total := 0;
    FOR r IN
      SELECT c.conrelid::regclass AS child, a.attname AS child_col, a.attnotnull AS notnull,
             c.confrelid::regclass AS parent, af.attname AS parent_col
      FROM pg_constraint c
      JOIN pg_attribute a  ON a.attrelid  = c.conrelid  AND a.attnum  = c.conkey[1]
      JOIN pg_attribute af ON af.attrelid = c.confrelid AND af.attnum = c.confkey[1]
      WHERE c.contype = 'f' AND array_length(c.conkey, 1) = 1
    LOOP
      IF r.notnull THEN
        EXECUTE format('DELETE FROM %s ch WHERE NOT EXISTS (SELECT 1 FROM %s p WHERE p.%I = ch.%I)',
                       r.child, r.parent, r.parent_col, r.child_col);
      ELSE
        EXECUTE format('UPDATE %s ch SET %I = NULL WHERE ch.%I IS NOT NULL AND NOT EXISTS (SELECT 1 FROM %s p WHERE p.%I = ch.%I)',
                       r.child, r.child_col, r.child_col, r.parent, r.parent_col, r.child_col);
      END IF;
      GET DIAGNOSTICS n = ROW_COUNT;
      IF n > 0 THEN
        total := total + n;
        RAISE NOTICE 'passe % : %.% -> % : % ligne(s) %', pass, r.child, r.child_col, r.parent, n,
          CASE WHEN r.notnull THEN 'supprimée(s)' ELSE 'mise(s) à NULL' END;
      END IF;
    END LOOP;
    EXIT WHEN total = 0 OR pass >= 10;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------
-- 11. VÉRIFICATIONS DE SÉCURITÉ : si l'une échoue, TOUT est annulé
-- ---------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth_user WHERE code = 'admin') THEN
    RAISE EXCEPTION 'Utilisateur admin supprimé : annulation';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM base_company WHERE name = 'Axelor') THEN
    RAISE EXCEPTION 'Société Axelor supprimée : annulation';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM base_partner WHERE name = 'Axelor') THEN
    RAISE EXCEPTION 'Tiers Axelor supprimé : annulation';
  END IF;
  IF EXISTS (SELECT 1 FROM auth_user u WHERE u.partner IS NOT NULL
             AND NOT EXISTS (SELECT 1 FROM base_partner p WHERE p.id = u.partner)) THEN
    RAISE EXCEPTION 'Un utilisateur pointe vers un tiers supprimé : annulation';
  END IF;
  IF EXISTS (SELECT 1 FROM auth_user u WHERE u.active_company IS NOT NULL
             AND NOT EXISTS (SELECT 1 FROM base_company c WHERE c.id = u.active_company)) THEN
    RAISE EXCEPTION 'Un utilisateur pointe vers une société supprimée : annulation';
  END IF;
END $$;

-- Réactivation des clés étrangères
SET session_replication_role = 'origin';

COMMIT;