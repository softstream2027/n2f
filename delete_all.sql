BEGIN;

-- 🚀 DÉSACTIVATION TEMPORAIRE DES CLÉS ÉTRANGÈRES POUR PERMETTRE LE NETTOYAGE MASSIF
SET session_replication_role = 'replica';

-- 1. NETTOYAGE DES TABLES LIEES AUX PRODUITS / VARIANTES
DELETE FROM account_tax_line WHERE end_date IS NOT NULL;
UPDATE base_Product SET default_Supplier_Partner = NULL;

DELETE FROM base_product_variant_config_product_variant_value1set;
DELETE FROM base_product_variant_config_product_variant_value2set;
DELETE FROM base_product_variant_config;
DELETE FROM base_product_variant;
DELETE FROM base_product_variant_value;

DELETE FROM supplychain_mrp_product_set;
DELETE FROM account_reconcile_payment_move_line_distribution_list;
DELETE FROM account_payment_move_line_distribution;

-- 2. NETTOYAGE COMPTABLE (Factures, Écritures, Paiements)
DELETE FROM account_pay_voucher_due_element;
DELETE FROM account_pay_voucher_element_to_pay;
UPDATE account_move SET payment_voucher = NULL;
DELETE FROM account_payment_voucher;

DELETE FROM account_invoice_line_tax_line_set;
DELETE FROM ACCOUNT_INVOICE_line;
DELETE FROM account_invoice_term_payment_reconcile_list;
DELETE FROM account_invoice_term_payment;
DELETE FROM account_invoice_term;
DELETE FROM account_invoice_line_tax;

UPDATE account_invoice SET move = NULL;
DELETE FROM account_move_line;
DELETE FROM account_invoice_payment;
DELETE FROM account_move;
DELETE FROM account_invoice_stock_move_set;

-- 3. PRODUCTION / PROJETS / TEMPS
DELETE FROM production_temp_bom_tree;
DELETE FROM project_project_task_tag_set;
DELETE FROM hr_timesheet_line;
DELETE FROM project_project_check_list_item;
DELETE FROM project_project_task_timer_list;
DELETE FROM project_project_planning_time;
DELETE FROM project_project_task;

-- 4. VENTES ET ACHATS (Stock et commandes)
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

DELETE FROM SALE_SALE_ORDER;
DELETE FROM purchase_purchase_order_line_tax_line_set;
DELETE FROM purchase_purchase_order_line;
DELETE FROM purchase_purchase_order_line_tax;
DELETE FROM PURCHASE_PURCHASE_ORDER;

-- 5. NOMENCLATURE (BOM) ET PROCESSUS
UPDATE base_product SET default_bill_of_material = NULL;
DELETE FROM hr_timesheet_line;
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
DELETE FROM account_payment_voucher;
DELETE FROM bankpayment_bank_statement_line_afb120;

-- 6. BANQUE ET PARTENAIRES (Nettoyage partiel initial)
DELETE FROM bankpayment_bank_order_line_origin;
DELETE FROM bankpayment_bank_order_line;
DELETE FROM base_bank_details WHERE PARTNER > 68;
DELETE FROM base_blocking_company_set;
DELETE FROM base_blocking WHERE PARTNER > 68;
DELETE FROM base_partner_address WHERE PARTNER > 68;
DELETE FROM base_partner_company_set WHERE BASE_PARTNER > 68;
DELETE FROM base_partner_contact_partner_set WHERE BASE_PARTNER > 68;

-- 7. CRM / EVENTS / RH
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
DELETE FROM crm_event_reminder;
DELETE FROM ical_event;
DELETE FROM base_trace_Back;
DELETE FROM auth_user_company_set WHERE auth_user NOT IN (SELECT id FROM auth_user WHERE code = 'admin');

-- 🛡️ PROTECTION : Mise à jour des utilisateurs SAUF admin
UPDATE auth_user SET partner = NULL, employee = NULL WHERE code != 'admin' AND code IS NOT NULL;
DELETE FROM auth_user WHERE code != 'admin' AND code IS NOT NULL;

DELETE FROM team_team_members WHERE members != 1;
DELETE FROM quality_qi_analysis_cause_qi_resolution_defaults_set;
DELETE FROM quality_qi_analysis_cause;
DELETE FROM sale_configurator_creator_authorized_user_set WHERE authorized_user_set != 1;
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
    SELECT 1 FROM hr_employee e JOIN auth_user u ON u.employee = e.id WHERE u.code = 'admin' AND e.main_Employment_Contract = hr_employment_contract.id
);
DELETE FROM hr_leave_management;
DELETE FROM hr_leave_line;
DELETE FROM hr_timesheet;
DELETE FROM hr_lunch_voucher_mgt_line;

DELETE FROM base_partner_address WHERE partner > 68;
DELETE FROM base_partner_address WHERE partner IN (SELECT id FROM base_partner WHERE id > 68 AND id NOT IN (SELECT partner FROM account_invoice));
DELETE FROM base_partner_company_set WHERE base_partner IN (SELECT id FROM base_partner WHERE id > 68 AND id NOT IN (SELECT partner FROM account_invoice));

UPDATE base_partner SET is_Customer = 'Y' WHERE id > 68 AND is_Customer = 'N' AND is_Supplier = 'N';

DELETE FROM helpdesk_ticket;
DELETE FROM hr_payroll_preparation_other_costs_employee_set;
DELETE FROM hr_payroll_preparation;

-- 🛡️ PROTECTION : Mise à jour du contrat principal SAUF pour l'admin
UPDATE hr_employee SET main_Employment_Contract = NULL 
WHERE NOT EXISTS (
    SELECT 1 FROM auth_user u WHERE u.code = 'admin' AND u.employee = hr_employee.id
);

-- 🛡️ PROTECTION : Suppression des contrats SAUF celui de l'admin
DELETE FROM hr_Employment_Contract 
WHERE NOT EXISTS (
    SELECT 1 FROM hr_employee e 
    JOIN auth_user u ON u.employee = e.id 
    WHERE u.code = 'admin' AND e.main_Employment_Contract = hr_Employment_Contract.id
);

DELETE FROM sale_cart_line;
DELETE FROM stock_stock_correction;
DELETE FROM base_Import_History;

-- 8. SUPPRESSION FINALE DES PRODUITS, EMPLOYES ET PARTENAIRES
-- 🛡️ PROTECTION : Suppression des articles SAUF ceux en NDF-% et ceux liés aux notes de frais
DELETE FROM BASE_PRODUCT 
WHERE code NOT LIKE 'NDF-%' 
  AND id NOT IN (SELECT product FROM hr_expense_line WHERE product IS NOT NULL);

DELETE FROM hr_employee_batch_set;

-- 🛡️ PROTECTION : Suppression des employés SAUF l'admin ET ceux qui ont des notes de frais
DELETE FROM hr_employee 
WHERE   NOT EXISTS (SELECT 1 FROM auth_user u WHERE u.code = 'admin' AND u.employee = hr_employee.id);

-- 🛡️ PROTECTION : Suppression des partenaires (on garde ceux liés aux notes de frais via l'employé)
DELETE FROM base_partner 
WHERE id > 68 
  AND id NOT IN (9007, 9013) ;

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

-- Mise à jour finale des produits (on ne touche pas aux NDF pour ne pas modifier leurs prix)
UPDATE base_product SET manag_Price_Coef = 1.35, purchase_Price = sale_Price / 1.35
WHERE code NOT LIKE 'NDF-%';

-- =====================================================================
-- 9. 🎯 NETTOYAGE CIBLÉ (Garder Admin, Axelor Company, Axelor Partner)
-- =====================================================================

-- A. Nettoyer les liaisons de l'utilisateur Admin
DELETE FROM auth_user_company_set WHERE auth_user NOT IN (SELECT id FROM auth_user WHERE code = 'admin');

-- B. Supprimer tous les UTILISATEURS sauf 'admin'
DELETE FROM auth_user WHERE code != 'admin' AND code IS NOT NULL;

-- C. Supprimer toutes les SOCIÉTÉS sauf 'Axelor' ET celles liées aux notes de frais
DELETE FROM base_company 
WHERE name != 'Axelor'  ;

-- D. Supprimer tous les TIERS (Partenaires) sauf 'Axelor'
DELETE FROM base_partner 
WHERE name != 'Axelor'  ;


DELETE from account_account_default_tax_set where account_account   in (select id from account_account where Company != 1);

 DELETE from account_account_management_sale_tax_set where account_account_management   in (select id from account_account_management where Company != 1);

 DELETE from account_account_management_purchase_tax_set where account_account_management   in (select id from account_account_management where Company != 1);


DELETE FROM account_Account_Management where Company != 1;

DELETE FROM   account_account_config_move_on_temp_closure_authorized_role_lis where account_account_config   in (select id from account_account_config where Company != 1);
DELETE FROM   account_account_config_closure_authorized_role_list where account_account_config   in (select id from account_account_config where Company != 1);
DELETE FROM   account_account_config_clearance_account_set where account_account_config   in (select id from account_account_config where Company != 1);
 DELETE FROM   account_invoice_product_statement where  account_config   in (select id from account_account_config where Company != 1);

DELETE FROM   account_account_config_temporary_closure_authorized_role_list where account_account_config   in (select id from account_account_config where Company != 1);


DELETE FROM account_account_config where Company != 1;

 DELETE FROM  account_journal_valid_account_set where valid_account_set  in (select id from account_account where Company != 1);
 
  DELETE FROM  account_account_equiv where from_account  in (select id from account_account where Company != 1);
  DELETE FROM  account_account_equiv where to_account  in (select id from account_account where Company != 1);

  DELETE FROM  account_account_compatible_account_set where compatible_account_set  in (select id from account_account where Company != 1);




DELETE FROM account_account where Company != 1;


-- =====================================================================

-- 🚀 RÉACTIVATION DES CLÉS ÉTRANGÈRES
SET session_replication_role = 'origin';

COMMIT;
