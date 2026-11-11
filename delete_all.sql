
  
  delete from  account_tax_line where end_date is not null ;

   update  base_Product set default_Supplier_Partner=null;
   delete  from supplychain_mrp_product_set ;
   
   delete from  account_reconcile_payment_move_line_distribution_list;

  delete from account_payment_move_line_distribution;
     delete from base_product_variant_config;

update production_manuf_order set product_variant_value1=null;
update production_manuf_order set product_variant_value2=null;
update production_manuf_order set product_variant_value3=null;
update production_manuf_order set product_variant_value4=null;
update production_manuf_order set product_variant_value5=null;
update production_manuf_order set product_variant_value6=null;
update production_manuf_order set product_variant_value7=null;
update production_manuf_order set product_variant_value8=null;
update production_manuf_order set product_variant_value9=null;
update production_manuf_order set product_variant_value10=null;
update production_manuf_order set product_variant_value11=null;
update production_manuf_order set product_variant_value12=null;
update production_manuf_order set product_variant_value13=null;
update production_manuf_order set product_variant_value14=null;
update production_manuf_order set product_variant_value15=null;
update production_manuf_order set product_variant_value16=null;

 delete from base_product_variant_value;
 delete from base_product_variant;
delete from base_product_variant_config_product_variant_value1set;
 delete from base_product_variant_config_product_variant_value2set;

 

     delete from account_pay_voucher_due_element;
     delete from account_pay_voucher_element_to_pay;
      update account_move set  payment_voucher=null ;

     delete from account_payment_voucher;

     delete from account_invoice_line_project_task_set;

     delete from account_invoice_line_tax_line_set;
 delete from ACCOUNT_INVOICE_line;
 delete from account_invoice_term_payment_reconcile_list;
 delete from account_invoice_term_payment;
 delete from account_invoice_term;
 delete from account_invoice_line_tax;

 update account_invoice  set move=null;
 delete from account_move_line;
 delete from account_invoice_payment;
 delete from account_move;
 delete from account_invoice_stock_move_set;

 
  delete from production_temp_bom_tree;
  delete from production_operation_order_employee_set;
  delete from project_project_task_tag_set;
  delete from hr_timesheet_line;

 delete from project_project_check_list_item;
 delete from project_project_check_list_item;
 delete from project_project_task_timer_list;
 
 delete from businessproject_invoicing_project_project_task_set;
 delete from businessproject_invoicing_project;
 delete from account_invoice;
 delete from sale_sale_order_line_tax_line_set;
 delete from project_project_planning_time;
 delete from project_project_task;
 delete from stock_inventory_line;
 delete from stock_stock_location_line_history;
 delete from stock_stock_location_line;
 update stock_stock_move_line set tracking_number=null ;
 delete from stock_tracking_number;
 delete from stock_logistical_form_line;
 delete from stock_stock_move_line;
 delete from production_cost_sheet_line;
 delete from production_cost_sheet;
 delete from production_manuf_order_production_order_set;
 delete from production_manuf_order_sale_order_set;
 delete from production_operation_order_duration;
 delete from production_operation_order;
 delete from production_prod_product;
 delete from production_production_order_manuf_order_set;
 delete from stock_stock_move_purchase_order_set;
 delete from stock_stock_move_sale_order_set;
 delete from stock_stock_move;
 delete from production_manuf_order;
 delete from quality_qi_identification_sourceqilist;
 delete from quality_quality_improvement;
 delete from quality_qi_identification;
  delete from  sale_complementary_product_selected;
 delete from sale_sale_order_line;
 delete from sale_sale_order_line_tax;
 delete from production_production_order;
 delete from SALE_SALE_ORDER;
 delete from purchase_purchase_order_line_tax_line_set;
 delete from purchase_purchase_order_line;
 delete from purchase_purchase_order_line_tax;
 delete from PURCHASE_PURCHASE_ORDER;

 update base_product set  default_bill_of_material=null;
 delete from hr_timesheet_line;
  delete from production_bill_of_material_line;
  delete from production_bill_of_material where name !='STD';
  
  delete from production_object_description;
  delete from production_prod_process_line;
  delete from production_prod_process where name !='STD';
delete from   supplychain_supplychain_batch_used_stock_rules_set;
 delete from stock_stock_rules;
 delete from supplychain_mrp_forecast;
 --delete from studio_app_production;
 delete from purchase_supplier_catalog;
 delete from sale_complementary_product;
 --delete from account_account_management;
 --delete from account_account_management_purchase_tax_set;
 --delete from account_account_management_sale_tax_set;
 delete from bankpayment_bank_statement_rule;
 --delete from account_account_management;
 delete from stock_inventory;
 delete from intervention_equipment_line;
 delete from hr_expense_line;
 delete from base_product_task_template_set;
 delete from stock_freight_carrier_mode;
 --delete from stock_shipment_mode;
 delete from account_move_template_line;
 delete from project_project_project_task_category_set;
 delete from project_project_task_category_project_task_status_set;
 delete from project_task_status_progress_by_category;
 delete from project_project_task_category;
 delete from  base_alternative_barcode;



 delete from stock_logistical_form;

 delete from account_payment_voucher;
 --delete from account_accounting_batch;
 delete from bankpayment_bank_statement_line_afb120;
 
 
 delete from bankpayment_bank_order_line_origin;
 delete from bankpayment_bank_order_line;
 delete from base_bank_details   where PARTNER>68;
 delete from base_blocking_company_set;
 delete from base_blocking  where PARTNER>68;
 delete from base_partner_address  where PARTNER>68;
 delete from base_partner_company_set  where BASE_PARTNER>68;
 delete from base_partner_contact_partner_set  where BASE_PARTNER>68;
 
 delete from ical_user;
 delete from crm_event_reminder;
 delete from ical_event;
 delete from crm_opportunity;
 delete from hr_extra_hours_line;
 delete from project_project_members_user_set;
 delete from project_project_project_task_priority_set;
 delete from project_project_project_task_status_set;
 delete from project_project;
 delete from quality_qi_resolution_decision;
 delete from stock_partner_stock_settings;
 delete from ical_event_qi_resolution_defaults_set;
 delete from hr_leave_request;
 delete from crm_event_reminder;
 delete from ical_event;
 delete from  base_trace_Back;
 delete from auth_user_company_set  where auth_user>30;
  update auth_user set partner=null,employee=null where id>30;
    update auth_user set employee=null  ;

   delete from auth_user  where id>30;
 delete from team_team_members  where members!=1;
 delete from quality_qi_analysis_cause_qi_resolution_defaults_set;
 delete from quality_qi_analysis_cause;
 delete from sale_configurator_creator_authorized_user_set where authorized_user_set!=1;
 delete from quality_qi_analysis;
 delete from intervention_customer_request_equipment_set;
 delete from intervention_intervention_equipment_set;
 delete from intervention_intervention;
 delete from intervention_customer_request;
 delete from quality_qi_process;
 
 delete from crm_lead;
 delete from fleet_vehicle_fuel_log;
 delete from fleet_vehicle_contract;
 delete from fleet_vehicle;
 --delete from contract_contract;
 delete from intervention_equipment;
 --delete from  base_partner_tag_set  ;
 --delete from  base_partner_contact_partner_set  ;
 update    hr_employment_contract set  employee=null  ;
 delete from  hr_leave_management   ;
 delete from  hr_leave_line   ;
 delete from  hr_timesheet   ;
 delete from  hr_lunch_voucher_mgt_line   ;
 --delete from  hr_employee   ;
 --update  BASE_PRODUCT set default_supplier_partner=null;
 ;
 delete from base_partner_address where partner >68;

delete from base_partner_address where partner in(select id from base_partner where   id >68 and  id not in(select partner from account_invoice));

delete from base_partner_company_set where base_partner in(select id from base_partner where   id >68 and  id not in(select partner from account_invoice));

 
update base_partner set is_Customer='Y' where   id >68  and is_Customer='N' and is_Supplier='N';


 delete from helpdesk_ticket;
 
delete from  hr_payroll_preparation_other_costs_employee_set;
delete from  hr_payroll_preparation;
update hr_employee set main_Employment_Contract=null;
delete from hr_Employment_Contract;



delete from sale_cart_line;
delete from stock_stock_correction;
delete from base_Import_History;

 delete from BASE_PRODUCT where code is   null  ;
 delete from BASE_PRODUCT    ;
 delete from hr_expense    ;
   update auth_user set partner=null,employee=null where id>30;

 delete from hr_employee_batch_set    ;
 delete from hr_employee    ;
 
   delete from  base_partner where id >68  and id not in(9007, 9013)
   and  id not in(select partner from account_invoice)
   and not exists
   (select 1 from account_accounting_situation  where base_partner.id=account_accounting_situation.partner );

 
 delete from base_pricing_line;

delete from base_pricing;
  delete from account_accounting_situation;
  delete from account_accounting_report_partner_set;
  
  update ical_user set event=null;
    delete from   ical_event;

  delete from   ical_user;
  delete from   crm_opportunity;
  delete from   supplychain_mrp_line_origin;
  delete from   supplychain_mrp_line;

  delete from  project_wiki;
delete from  businesssupport_project_announcement;
    delete from   project_project;
 delete from   account_payment_session_partner_set;

------------ update base_product set manag_Price_Coef=1.35,purchase_Price=sale_Price/1.35;
 