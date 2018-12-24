CREATE TABLE `accounts` (
  `id` varchar(36) NOT NULL default '',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) NOT NULL default '',
  `assigned_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `name` varchar(150) default NULL,
  `parent_id` varchar(36) default NULL,
  `account_type` varchar(25) default NULL,
  `industry` varchar(25) default NULL,
  `annual_revenue` varchar(25) default NULL,
  `phone_fax` varchar(25) default NULL,
  `billing_address_street` varchar(150) default NULL,
  `billing_address_city` varchar(100) default NULL,
  `billing_address_state` varchar(100) default NULL,
  `billing_address_postalcode` varchar(20) default NULL,
  `billing_address_country` varchar(100) default NULL,
  `description` text,
  `rating` varchar(25) default NULL,
  `phone_office` varchar(25) default NULL,
  `phone_alternate` varchar(25) default NULL,
  `email1` varchar(100) default NULL,
  `email2` varchar(100) default NULL,
  `website` varchar(255) default NULL,
  `ownership` varchar(100) default NULL,
  `employees` varchar(10) default NULL,
  `sic_code` varchar(11) default NULL,
  `ticker_symbol` varchar(10) default NULL,
  `shipping_address_street` varchar(150) default NULL,
  `shipping_address_city` varchar(100) default NULL,
  `shipping_address_state` varchar(100) default NULL,
  `shipping_address_postalcode` varchar(20) default NULL,
  `shipping_address_country` varchar(100) default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  `campaign_id` varchar(36) default NULL,
  PRIMARY KEY  (`id`),
  KEY `idx_accnt_id_del` (`id`,`deleted`),
  KEY `idx_accnt_assigned_del` (`deleted`,`assigned_user_id`),
  KEY `idx_accnt_parent_id` (`parent_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `accounts_audit` (
  `id` varchar(36) NOT NULL default '',
  `parent_id` varchar(36) NOT NULL default '',
  `date_created` datetime default NULL,
  `created_by` varchar(36) default NULL,
  `field_name` varchar(100) default NULL,
  `data_type` varchar(100) default NULL,
  `before_value_string` varchar(255) default NULL,
  `after_value_string` varchar(255) default NULL,
  `before_value_text` text,
  `after_value_text` text
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `accounts_bugs` (
  `id` varchar(36) NOT NULL default '',
  `account_id` varchar(36) default NULL,
  `bug_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_acc_bug_acc` (`account_id`),
  KEY `idx_acc_bug_bug` (`bug_id`),
  KEY `idx_account_bug` (`account_id`,`bug_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `accounts_cases` (
  `id` varchar(36) NOT NULL default '',
  `account_id` varchar(36) default NULL,
  `case_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_acc_case_acc` (`account_id`),
  KEY `idx_acc_acc_case` (`case_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `accounts_contacts` (
  `id` varchar(36) NOT NULL default '',
  `contact_id` varchar(36) default NULL,
  `account_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_acc_cont_acc` (`account_id`),
  KEY `idx_acc_cont_cont` (`contact_id`),
  KEY `idx_account_contact` (`account_id`,`contact_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `accounts_opportunities` (
  `id` varchar(36) NOT NULL default '',
  `opportunity_id` varchar(36) default NULL,
  `account_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_acc_opp_acc` (`account_id`),
  KEY `idx_acc_opp_opp` (`opportunity_id`),
  KEY `idx_a_o_opp_acc_del` (`opportunity_id`,`account_id`,`deleted`),
  KEY `idx_account_opportunity` (`account_id`,`opportunity_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `acl_actions` (
  `id` varchar(36) NOT NULL default '',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) NOT NULL default '',
  `created_by` varchar(36) default NULL,
  `name` varchar(150) default NULL,
  `category` varchar(100) default NULL,
  `acltype` varchar(100) default NULL,
  `aclaccess` int(3) default NULL,
  `deleted` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_aclaction_id_del` (`id`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `acl_roles` (
  `id` varchar(36) NOT NULL default '',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) NOT NULL default '',
  `created_by` varchar(36) default NULL,
  `name` varchar(150) default NULL,
  `description` text,
  `deleted` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_aclrole_id_del` (`id`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `acl_roles_actions` (
  `id` varchar(36) NOT NULL default '',
  `role_id` varchar(36) default NULL,
  `action_id` varchar(36) default NULL,
  `access_override` int(3) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_acl_role_id` (`role_id`),
  KEY `idx_acl_action_id` (`action_id`),
  KEY `idx_aclrole_action` (`role_id`,`action_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `acl_roles_users` (
  `id` varchar(36) NOT NULL default '',
  `role_id` varchar(36) default NULL,
  `user_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_aclrole_id` (`role_id`),
  KEY `idx_acluser_id` (`user_id`),
  KEY `idx_aclrole_user` (`role_id`,`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `areas` (
  `id` bigint(11) NOT NULL auto_increment,
  `nombre` varchar(64) NOT NULL default '',
  `orden` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `atributos` (
  `id` bigint(11) NOT NULL auto_increment,
  `producto_id` bigint(11) default NULL,
  `nombre` varchar(255) default NULL,
  `valor` text,
  `orden` int(11) default NULL,
  `tipo` char(3) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `atributos_detalles` (
  `id` bigint(11) NOT NULL auto_increment,
  `detalle_id` bigint(11) default NULL,
  `nombre` varchar(255) default NULL,
  `valor` text,
  `orden` int(11) default NULL,
  `tipo` char(3) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `bugs` (
  `id` varchar(36) NOT NULL default '',
  `bug_number` int(11) NOT NULL auto_increment,
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) NOT NULL default '',
  `assigned_user_id` varchar(36) default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  `name` varchar(255) default NULL,
  `status` varchar(25) default NULL,
  `priority` varchar(25) default NULL,
  `description` text,
  `created_by` varchar(36) default NULL,
  `resolution` varchar(255) default NULL,
  `found_in_release` varchar(255) default NULL,
  `type` varchar(255) default NULL,
  `fixed_in_release` varchar(255) default NULL,
  `work_log` text,
  `source` varchar(255) default NULL,
  `product_category` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `bug_number` (`bug_number`),
  KEY `idx_bug_name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `bugs_audit` (
  `id` varchar(36) NOT NULL default '',
  `parent_id` varchar(36) NOT NULL default '',
  `date_created` datetime default NULL,
  `created_by` varchar(36) default NULL,
  `field_name` varchar(100) default NULL,
  `data_type` varchar(100) default NULL,
  `before_value_string` varchar(255) default NULL,
  `after_value_string` varchar(255) default NULL,
  `before_value_text` text,
  `after_value_text` text
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `calls` (
  `id` varchar(36) NOT NULL default '',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `assigned_user_id` varchar(36) default NULL,
  `modified_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `name` varchar(50) default NULL,
  `duration_hours` int(2) default NULL,
  `duration_minutes` int(2) default NULL,
  `date_start` date default NULL,
  `time_start` time default NULL,
  `date_end` date default NULL,
  `parent_type` varchar(25) default NULL,
  `status` varchar(25) default NULL,
  `direction` varchar(25) default NULL,
  `parent_id` varchar(36) default NULL,
  `description` text,
  `deleted` tinyint(1) NOT NULL default '0',
  `reminder_time` int(4) default '-1',
  `outlook_id` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `idx_call_name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `calls_contacts` (
  `id` varchar(36) NOT NULL default '',
  `call_id` varchar(36) default NULL,
  `contact_id` varchar(36) default NULL,
  `required` char(1) default '1',
  `accept_status` varchar(25) default 'none',
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_con_call_call` (`call_id`),
  KEY `idx_con_call_con` (`contact_id`),
  KEY `idx_call_contact` (`call_id`,`contact_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `calls_users` (
  `id` varchar(36) NOT NULL default '',
  `call_id` varchar(36) default NULL,
  `user_id` varchar(36) default NULL,
  `required` char(1) default '1',
  `accept_status` varchar(25) default 'none',
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_usr_call_call` (`call_id`),
  KEY `idx_usr_call_usr` (`user_id`),
  KEY `idx_call_users` (`call_id`,`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `campaign_log` (
  `id` varchar(36) NOT NULL default '',
  `campaign_id` varchar(36) default NULL,
  `target_tracker_key` varchar(36) default NULL,
  `target_id` varchar(36) default NULL,
  `target_type` varchar(25) default NULL,
  `activity_type` varchar(25) default NULL,
  `activity_date` datetime default NULL,
  `related_id` varchar(36) default NULL,
  `related_type` varchar(25) default NULL,
  `archived` tinyint(1) default '0',
  `hits` int(11) default '0',
  `list_id` varchar(36) default NULL,
  `deleted` tinyint(1) default '0',
  `date_modified` datetime default NULL,
  `more_information` varchar(100) default NULL,
  `marketing_id` varchar(36) default NULL,
  PRIMARY KEY  (`id`),
  KEY `idx_camp_tracker` (`target_tracker_key`),
  KEY `idx_camp_campaign_id` (`campaign_id`),
  KEY `idx_camp_more_info` (`more_information`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `campaign_trkrs` (
  `id` varchar(36) NOT NULL default '',
  `tracker_name` varchar(30) default NULL,
  `tracker_url` varchar(255) default 'http://',
  `tracker_key` int(11) NOT NULL auto_increment,
  `campaign_id` varchar(36) default NULL,
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `is_optout` tinyint(1) NOT NULL default '0',
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `campaign_tracker_key_idx` (`tracker_key`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `campaigns` (
  `id` varchar(36) NOT NULL default '',
  `tracker_key` int(11) NOT NULL auto_increment,
  `tracker_count` int(11) default '0',
  `name` varchar(50) default NULL,
  `refer_url` varchar(255) default 'http://',
  `tracker_text` varchar(255) default NULL,
  `date_entered` datetime default NULL,
  `date_modified` datetime default NULL,
  `modified_user_id` varchar(36) default NULL,
  `assigned_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  `start_date` date default NULL,
  `end_date` date default NULL,
  `status` varchar(25) default NULL,
  `impressions` int(11) default '0',
  `currency_id` varchar(36) default NULL,
  `budget` double default NULL,
  `expected_cost` double default NULL,
  `actual_cost` double default NULL,
  `expected_revenue` double default NULL,
  `campaign_type` varchar(25) default NULL,
  `objective` text,
  `content` text,
  `frequency` varchar(25) default NULL,
  PRIMARY KEY  (`id`),
  KEY `camp_auto_tracker_key` (`tracker_key`),
  KEY `idx_campaign_name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `campaigns_audit` (
  `id` varchar(36) NOT NULL default '',
  `parent_id` varchar(36) NOT NULL default '',
  `date_created` datetime default NULL,
  `created_by` varchar(36) default NULL,
  `field_name` varchar(100) default NULL,
  `data_type` varchar(100) default NULL,
  `before_value_string` varchar(255) default NULL,
  `after_value_string` varchar(255) default NULL,
  `before_value_text` text,
  `after_value_text` text
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `cases` (
  `id` varchar(36) NOT NULL default '',
  `case_number` int(11) NOT NULL auto_increment,
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) NOT NULL default '',
  `assigned_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  `name` varchar(255) default NULL,
  `account_id` varchar(36) default NULL,
  `status` varchar(25) default NULL,
  `priority` varchar(25) default NULL,
  `description` text,
  `resolution` text,
  PRIMARY KEY  (`id`),
  KEY `case_number` (`case_number`),
  KEY `idx_case_name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `cases_audit` (
  `id` varchar(36) NOT NULL default '',
  `parent_id` varchar(36) NOT NULL default '',
  `date_created` datetime default NULL,
  `created_by` varchar(36) default NULL,
  `field_name` varchar(100) default NULL,
  `data_type` varchar(100) default NULL,
  `before_value_string` varchar(255) default NULL,
  `after_value_string` varchar(255) default NULL,
  `before_value_text` text,
  `after_value_text` text
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `cases_bugs` (
  `id` varchar(36) NOT NULL default '',
  `case_id` varchar(36) default NULL,
  `bug_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_cas_bug_cas` (`case_id`),
  KEY `idx_cas_bug_bug` (`bug_id`),
  KEY `idx_case_bug` (`case_id`,`bug_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `categorias` (
  `id` bigint(11) NOT NULL auto_increment,
  `tipo` char(1) default NULL,
  `nombre` varchar(255) default NULL,
  `descripcion` text,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `config` (
  `category` varchar(32) default NULL,
  `name` varchar(32) default NULL,
  `value` text,
  KEY `idx_config_cat` (`category`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `contacts` (
  `id` varchar(36) NOT NULL default '',
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) default NULL,
  `assigned_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `salutation` varchar(5) default NULL,
  `first_name` varchar(100) default NULL,
  `last_name` varchar(100) default NULL,
  `lead_source` varchar(100) default NULL,
  `title` varchar(50) default NULL,
  `department` varchar(100) default NULL,
  `reports_to_id` varchar(36) default NULL,
  `birthdate` date default NULL,
  `do_not_call` char(3) default '0',
  `phone_home` varchar(25) default NULL,
  `phone_mobile` varchar(25) default NULL,
  `phone_work` varchar(25) default NULL,
  `phone_other` varchar(25) default NULL,
  `phone_fax` varchar(25) default NULL,
  `email1` varchar(100) default NULL,
  `email2` varchar(100) default NULL,
  `assistant` varchar(75) default NULL,
  `assistant_phone` varchar(25) default NULL,
  `email_opt_out` char(3) default '0',
  `primary_address_street` varchar(150) default NULL,
  `primary_address_city` varchar(100) default NULL,
  `primary_address_state` varchar(100) default NULL,
  `primary_address_postalcode` varchar(20) default NULL,
  `primary_address_country` varchar(100) default NULL,
  `alt_address_street` varchar(150) default NULL,
  `alt_address_city` varchar(100) default NULL,
  `alt_address_state` varchar(100) default NULL,
  `alt_address_postalcode` varchar(20) default NULL,
  `alt_address_country` varchar(100) default NULL,
  `description` text,
  `portal_name` varchar(255) default NULL,
  `portal_active` tinyint(1) NOT NULL default '0',
  `portal_app` varchar(255) default NULL,
  `invalid_email` tinyint(1) default '0',
  `campaign_id` varchar(36) default NULL,
  PRIMARY KEY  (`id`),
  KEY `idx_cont_last_first` (`last_name`,`first_name`,`deleted`),
  KEY `idx_contacts_del_last` (`deleted`,`last_name`),
  KEY `idx_cont_del_reports` (`deleted`,`reports_to_id`,`last_name`),
  KEY `idx_cont_assigned` (`assigned_user_id`),
  KEY `idx_cont_email1` (`email1`),
  KEY `idx_cont_email2` (`email2`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `contacts_audit` (
  `id` varchar(36) NOT NULL default '',
  `parent_id` varchar(36) NOT NULL default '',
  `date_created` datetime default NULL,
  `created_by` varchar(36) default NULL,
  `field_name` varchar(100) default NULL,
  `data_type` varchar(100) default NULL,
  `before_value_string` varchar(255) default NULL,
  `after_value_string` varchar(255) default NULL,
  `before_value_text` text,
  `after_value_text` text
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `contacts_bugs` (
  `id` varchar(36) NOT NULL default '',
  `contact_id` varchar(36) default NULL,
  `bug_id` varchar(36) default NULL,
  `contact_role` varchar(50) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_con_bug_con` (`contact_id`),
  KEY `idx_con_bug_bug` (`bug_id`),
  KEY `idx_contact_bug` (`contact_id`,`bug_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `contacts_cases` (
  `id` varchar(36) NOT NULL default '',
  `contact_id` varchar(36) default NULL,
  `case_id` varchar(36) default NULL,
  `contact_role` varchar(50) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_con_case_con` (`contact_id`),
  KEY `idx_con_case_case` (`case_id`),
  KEY `idx_contacts_cases` (`contact_id`,`case_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `contacts_users` (
  `id` varchar(36) NOT NULL default '',
  `contact_id` varchar(36) default NULL,
  `user_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_con_users_con` (`contact_id`),
  KEY `idx_con_users_user` (`user_id`),
  KEY `idx_contacts_users` (`contact_id`,`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `cotizacion_detalles` (
  `id` bigint(11) NOT NULL auto_increment,
  `cotizacion_id` bigint(11) default NULL,
  `nombre` varchar(255) default NULL,
  `cantidad` int(11) default NULL,
  `producto_id` bigint(11) default NULL,
  `servicio_id` bigint(11) default NULL,
  `tipo` char(1) default NULL,
  `precio` float default NULL,
  `descripcion` text,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `cotizaciones` (
  `id` bigint(11) NOT NULL auto_increment,
  `codigo` varchar(16) default NULL,
  `proyecto_id` bigint(11) NOT NULL default '0',
  `version` int(11) default NULL,
  `tiempo_de_entrega` int(11) default NULL,
  `forma_de_pago` varchar(255) default NULL,
  `moneda` char(1) default NULL,
  `notas` text,
  `incluir_gran_total` char(1) default NULL,
  `especificar_detalles` char(1) default NULL,
  `created_on` datetime default NULL,
  `marked` char(1) default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `currencies` (
  `id` varchar(36) NOT NULL default '',
  `name` varchar(36) NOT NULL default '',
  `symbol` varchar(36) NOT NULL default '',
  `iso4217` char(3) NOT NULL default '',
  `conversion_rate` double NOT NULL default '0',
  `status` varchar(25) default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `created_by` varchar(36) NOT NULL default '',
  PRIMARY KEY  (`id`),
  KEY `idx_currency_name` (`name`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `custom_fields` (
  `bean_id` varchar(36) default NULL,
  `set_num` int(11) default '0',
  `field0` varchar(255) default NULL,
  `field1` varchar(255) default NULL,
  `field2` varchar(255) default NULL,
  `field3` varchar(255) default NULL,
  `field4` varchar(255) default NULL,
  `field5` varchar(255) default NULL,
  `field6` varchar(255) default NULL,
  `field7` varchar(255) default NULL,
  `field8` varchar(255) default NULL,
  `field9` varchar(255) default NULL,
  `deleted` tinyint(1) default '0',
  KEY `idx_beanid_set_num` (`bean_id`,`set_num`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `dashboards` (
  `id` varchar(36) NOT NULL default '',
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) NOT NULL default '',
  `assigned_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `name` varchar(100) default NULL,
  `description` text,
  `content` text,
  PRIMARY KEY  (`id`),
  KEY `idx_dashboard_name` (`name`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `detalles` (
  `id` bigint(11) NOT NULL auto_increment,
  `proyecto_id` bigint(11) default NULL,
  `cantidad` int(11) default NULL,
  `producto_id` bigint(11) default NULL,
  `tipo` char(1) default NULL,
  `servicio_id` bigint(11) NOT NULL default '0',
  `observaciones` text,
  `aprobado` char(1) default '0',
  `descripcion` text,
  `precio` float default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `document_revisions` (
  `id` varchar(36) NOT NULL default '',
  `change_log` varchar(255) default NULL,
  `document_id` varchar(36) default NULL,
  `date_entered` datetime default NULL,
  `created_by` varchar(36) default NULL,
  `filename` varchar(255) NOT NULL default '',
  `file_ext` varchar(25) default NULL,
  `file_mime_type` varchar(100) default NULL,
  `revision` varchar(25) default NULL,
  `deleted` tinyint(1) default '0',
  `date_modified` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `documents` (
  `id` varchar(36) NOT NULL default '',
  `document_name` varchar(255) NOT NULL default '',
  `active_date` date default NULL,
  `exp_date` date default NULL,
  `description` text,
  `category_id` varchar(25) default NULL,
  `subcategory_id` varchar(25) default NULL,
  `status_id` varchar(25) default NULL,
  `date_entered` datetime default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) default '0',
  `modified_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `document_revision_id` varchar(36) default NULL,
  `mail_merge_document` char(3) default 'off',
  `related_doc_id` varchar(36) default NULL,
  `related_doc_rev_id` varchar(36) default NULL,
  `is_template` tinyint(1) default '0',
  `template_type` varchar(25) default NULL,
  PRIMARY KEY  (`id`),
  KEY `idx_doc_cat` (`category_id`,`subcategory_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `email_marketing` (
  `id` varchar(36) NOT NULL default '',
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `name` varchar(255) default NULL,
  `from_addr` varchar(100) default NULL,
  `from_name` varchar(100) default NULL,
  `inbound_email_id` varchar(36) default NULL,
  `date_start` date default NULL,
  `time_start` time default NULL,
  `template_id` varchar(36) NOT NULL default '',
  `status` varchar(25) NOT NULL default '',
  `campaign_id` varchar(36) default NULL,
  `all_prospect_lists` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_emmkt_name` (`name`),
  KEY `idx_emmkit_del` (`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `email_marketing_prospect_lists` (
  `id` varchar(36) NOT NULL default '',
  `prospect_list_id` varchar(36) default NULL,
  `email_marketing_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `email_mp_prospects` (`email_marketing_id`,`prospect_list_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `email_templates` (
  `id` varchar(36) NOT NULL default '',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `published` char(3) default NULL,
  `name` varchar(255) default NULL,
  `description` text,
  `subject` varchar(255) default NULL,
  `body` text,
  `body_html` text,
  `deleted` tinyint(1) NOT NULL default '0',
  `text_only` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_email_template_name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `emailman` (
  `date_entered` datetime default NULL,
  `date_modified` datetime default NULL,
  `user_id` varchar(36) default NULL,
  `id` int(11) NOT NULL auto_increment,
  `campaign_id` varchar(36) default NULL,
  `marketing_id` varchar(36) default NULL,
  `list_id` varchar(36) default NULL,
  `send_date_time` datetime default NULL,
  `modified_user_id` varchar(36) default NULL,
  `in_queue` tinyint(1) default '0',
  `in_queue_date` datetime default NULL,
  `send_attempts` int(11) default '0',
  `deleted` tinyint(1) default '0',
  `related_id` varchar(36) default NULL,
  `related_type` varchar(100) default NULL,
  PRIMARY KEY  (`id`),
  KEY `idx_eman_list` (`list_id`,`user_id`,`deleted`),
  KEY `idx_eman_campaign_id` (`campaign_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `emails` (
  `id` varchar(36) NOT NULL default '',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `assigned_user_id` varchar(36) default NULL,
  `modified_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `name` varchar(255) default NULL,
  `date_start` date default NULL,
  `time_start` time default NULL,
  `parent_type` varchar(25) default NULL,
  `parent_id` varchar(36) default NULL,
  `description` longtext,
  `description_html` longtext,
  `from_addr` varchar(100) default NULL,
  `from_name` varchar(100) default NULL,
  `to_addrs` text,
  `cc_addrs` text,
  `bcc_addrs` text,
  `to_addrs_ids` text,
  `to_addrs_names` text,
  `to_addrs_emails` text,
  `cc_addrs_ids` text,
  `cc_addrs_names` text,
  `cc_addrs_emails` text,
  `bcc_addrs_ids` text,
  `bcc_addrs_names` text,
  `bcc_addrs_emails` text,
  `type` varchar(25) default NULL,
  `status` varchar(25) default NULL,
  `message_id` varchar(100) default NULL,
  `reply_to_name` varchar(100) default NULL,
  `reply_to_addr` varchar(100) default NULL,
  `intent` varchar(25) default 'pick',
  `mailbox_id` varchar(36) default NULL,
  `raw_source` longtext,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_email_name` (`name`),
  KEY `idx_message_id` (`message_id`),
  KEY `idx_email_parent_id` (`parent_id`),
  KEY `idx_email_assigned` (`assigned_user_id`,`type`,`status`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `emails_accounts` (
  `id` varchar(36) NOT NULL default '',
  `email_id` varchar(36) default NULL,
  `account_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_acc_email_email` (`email_id`),
  KEY `idx_acc_email_acc` (`account_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `emails_bugs` (
  `id` varchar(36) NOT NULL default '',
  `email_id` varchar(36) default NULL,
  `bug_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_bug_email_email` (`email_id`),
  KEY `idx_bug_email_bug` (`bug_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `emails_cases` (
  `id` varchar(36) NOT NULL default '',
  `email_id` varchar(36) default NULL,
  `case_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_case_email_email` (`email_id`),
  KEY `idx_case_email_case` (`case_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `emails_contacts` (
  `id` varchar(36) NOT NULL default '',
  `email_id` varchar(36) default NULL,
  `contact_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `campaign_data` text,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_con_email_email` (`email_id`),
  KEY `idx_con_email_con` (`contact_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `emails_leads` (
  `id` varchar(36) NOT NULL default '',
  `email_id` varchar(36) default NULL,
  `lead_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `campaign_data` text,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_lead_email_email` (`email_id`),
  KEY `idx_lead_email_lead` (`lead_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `emails_opportunities` (
  `id` varchar(36) NOT NULL default '',
  `email_id` varchar(36) default NULL,
  `opportunity_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_opp_email_email` (`email_id`),
  KEY `idx_opp_email_opp` (`opportunity_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `emails_project_tasks` (
  `id` varchar(36) NOT NULL default '',
  `email_id` varchar(36) default NULL,
  `project_task_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_ept_email` (`email_id`),
  KEY `idx_ept_project_task` (`project_task_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `emails_projects` (
  `id` varchar(36) NOT NULL default '',
  `email_id` varchar(36) default NULL,
  `project_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_project_email_email` (`email_id`),
  KEY `idx_project_email_project` (`project_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `emails_prospects` (
  `id` varchar(36) NOT NULL default '',
  `email_id` varchar(36) default NULL,
  `prospect_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `campaign_data` text,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_prospect_email_email` (`email_id`),
  KEY `idx_prospect_email_prospect` (`prospect_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `emails_tasks` (
  `id` varchar(36) NOT NULL default '',
  `email_id` varchar(36) default NULL,
  `task_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_task_email_email` (`email_id`),
  KEY `idx_task_email_task` (`task_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `emails_users` (
  `id` varchar(36) NOT NULL default '',
  `email_id` varchar(36) default NULL,
  `user_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `campaign_data` text,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_usr_email_email` (`email_id`),
  KEY `idx_usr_email_usr` (`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `feeds` (
  `id` varchar(36) NOT NULL default '',
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) NOT NULL default '',
  `assigned_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `title` varchar(100) default NULL,
  `description` text,
  `url` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `idx_feed_name` (`title`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `fields_meta_data` (
  `id` varchar(255) NOT NULL default '',
  `name` varchar(255) default NULL,
  `label` varchar(255) default NULL,
  `help` varchar(255) default NULL,
  `custom_module` varchar(255) default NULL,
  `data_type` varchar(255) default NULL,
  `max_size` int(11) default NULL,
  `required_option` varchar(255) default NULL,
  `default_value` varchar(255) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) default '0',
  `audited` tinyint(1) default '0',
  `mass_update` tinyint(1) default '0',
  `duplicate_merge` smallint(6) default '0',
  `ext1` varchar(255) default '',
  `ext2` varchar(255) default '',
  `ext3` varchar(255) default '',
  `ext4` text,
  PRIMARY KEY  (`id`),
  KEY `idx_meta_id_del` (`id`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `files` (
  `id` varchar(36) NOT NULL default '',
  `name` varchar(36) default NULL,
  `content` blob,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `assigned_user_id` varchar(36) default NULL,
  PRIMARY KEY  (`id`),
  KEY `idx_cont_owner_id_and_name` (`assigned_user_id`,`name`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `iframes` (
  `id` varchar(36) NOT NULL default '',
  `name` varchar(255) NOT NULL default '',
  `url` varchar(255) NOT NULL default '',
  `type` varchar(255) NOT NULL default '',
  `placement` varchar(255) NOT NULL default '',
  `status` tinyint(1) NOT NULL default '0',
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `created_by` varchar(36) NOT NULL default '',
  PRIMARY KEY  (`id`),
  KEY `idx_cont_name` (`name`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `import_maps` (
  `id` varchar(36) NOT NULL default '',
  `name` varchar(36) NOT NULL default '',
  `source` varchar(36) NOT NULL default '',
  `module` varchar(36) NOT NULL default '',
  `content` blob,
  `has_header` tinyint(1) NOT NULL default '1',
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `assigned_user_id` varchar(36) default NULL,
  `is_published` char(3) NOT NULL default 'no',
  PRIMARY KEY  (`id`),
  KEY `idx_owner_module_name` (`assigned_user_id`,`module`,`name`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `inbound_email` (
  `id` varchar(36) NOT NULL default '',
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `name` varchar(255) default NULL,
  `status` varchar(25) NOT NULL default 'Active',
  `server_url` varchar(100) NOT NULL default '',
  `email_user` varchar(100) NOT NULL default '',
  `email_password` varchar(100) NOT NULL default '',
  `port` int(5) NOT NULL default '0',
  `service` varchar(50) NOT NULL default '',
  `mailbox` varchar(50) NOT NULL default '',
  `delete_seen` tinyint(1) default '0',
  `mailbox_type` varchar(10) default NULL,
  `template_id` varchar(36) default NULL,
  `stored_options` text,
  `group_id` varchar(36) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `inbound_email_autoreply` (
  `id` varchar(36) NOT NULL default '',
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `autoreplied_to` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`id`),
  KEY `idx_ie_autoreplied_to` (`autoreplied_to`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `leads` (
  `id` varchar(36) NOT NULL default '',
  `deleted` tinyint(1) NOT NULL default '0',
  `converted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) default NULL,
  `assigned_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `salutation` varchar(5) default NULL,
  `first_name` varchar(25) default NULL,
  `last_name` varchar(25) default NULL,
  `title` varchar(100) default NULL,
  `refered_by` varchar(100) default NULL,
  `lead_source` varchar(100) default NULL,
  `lead_source_description` text,
  `status` varchar(100) default NULL,
  `status_description` text,
  `department` varchar(100) default NULL,
  `reports_to_id` varchar(36) default NULL,
  `do_not_call` char(3) default '0',
  `phone_home` varchar(25) default NULL,
  `phone_mobile` varchar(25) default NULL,
  `phone_work` varchar(25) default NULL,
  `phone_other` varchar(25) default NULL,
  `phone_fax` varchar(25) default NULL,
  `email1` varchar(100) default NULL,
  `email2` varchar(100) default NULL,
  `email_opt_out` char(3) default '0',
  `primary_address_street` varchar(150) default NULL,
  `primary_address_city` varchar(100) default NULL,
  `primary_address_state` varchar(100) default NULL,
  `primary_address_postalcode` varchar(20) default NULL,
  `primary_address_country` varchar(100) default NULL,
  `alt_address_street` varchar(150) default NULL,
  `alt_address_city` varchar(100) default NULL,
  `alt_address_state` varchar(100) default NULL,
  `alt_address_postalcode` varchar(20) default NULL,
  `alt_address_country` varchar(100) default NULL,
  `description` text,
  `account_name` varchar(150) default NULL,
  `account_description` text,
  `contact_id` varchar(36) default NULL,
  `account_id` varchar(36) default NULL,
  `opportunity_id` varchar(36) default NULL,
  `opportunity_name` varchar(255) default NULL,
  `opportunity_amount` varchar(50) default NULL,
  `campaign_id` varchar(36) default NULL,
  `portal_name` varchar(255) default NULL,
  `portal_app` varchar(255) default NULL,
  `invalid_email` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_lead_last_first` (`last_name`,`first_name`,`deleted`),
  KEY `idx_lead_del_stat` (`last_name`,`status`,`deleted`,`first_name`),
  KEY `idx_lead_opp_del` (`opportunity_id`,`deleted`),
  KEY `idx_leads_acct_del` (`account_id`,`deleted`),
  KEY `idx_lead_email1` (`email1`,`deleted`),
  KEY `idx_lead_email2` (`email2`,`deleted`),
  KEY `idx_lead_assigned` (`assigned_user_id`),
  KEY `idx_lead_contact` (`contact_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `leads_audit` (
  `id` varchar(36) NOT NULL default '',
  `parent_id` varchar(36) NOT NULL default '',
  `date_created` datetime default NULL,
  `created_by` varchar(36) default NULL,
  `field_name` varchar(100) default NULL,
  `data_type` varchar(100) default NULL,
  `before_value_string` varchar(255) default NULL,
  `after_value_string` varchar(255) default NULL,
  `before_value_text` text,
  `after_value_text` text
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `linked_documents` (
  `id` varchar(36) NOT NULL default '',
  `parent_id` varchar(36) default NULL,
  `parent_type` varchar(25) default NULL,
  `document_id` varchar(36) default NULL,
  `document_revision_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `meetings` (
  `id` varchar(36) NOT NULL default '',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `assigned_user_id` varchar(36) default NULL,
  `modified_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `name` varchar(50) default NULL,
  `location` varchar(50) default NULL,
  `duration_hours` int(2) default NULL,
  `duration_minutes` int(2) default NULL,
  `date_start` date default NULL,
  `time_start` time default NULL,
  `date_end` date default NULL,
  `parent_type` varchar(25) default NULL,
  `status` varchar(25) default NULL,
  `parent_id` varchar(36) default NULL,
  `description` text,
  `deleted` tinyint(1) NOT NULL default '0',
  `reminder_time` int(11) default '-1',
  `outlook_id` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `idx_mtg_name` (`name`),
  KEY `idx_meet_par_del` (`parent_id`,`parent_type`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `meetings_contacts` (
  `id` varchar(36) NOT NULL default '',
  `meeting_id` varchar(36) default NULL,
  `contact_id` varchar(36) default NULL,
  `required` char(1) default '1',
  `accept_status` varchar(25) default 'none',
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_con_mtg_mtg` (`meeting_id`),
  KEY `idx_con_mtg_con` (`contact_id`),
  KEY `idx_meeting_contact` (`meeting_id`,`contact_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `meetings_users` (
  `id` varchar(36) NOT NULL default '',
  `meeting_id` varchar(36) default NULL,
  `user_id` varchar(36) default NULL,
  `required` char(1) default '1',
  `accept_status` varchar(25) default 'none',
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_usr_mtg_mtg` (`meeting_id`),
  KEY `idx_usr_mtg_usr` (`user_id`),
  KEY `idx_meeting_users` (`meeting_id`,`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `mensajes` (
  `id` bigint(11) NOT NULL auto_increment,
  `proyecto_id` bigint(11) NOT NULL default '0',
  `area_id` int(11) default NULL,
  `mensaje` text,
  `user_id` varchar(36) NOT NULL default '',
  `fecha` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `notes` (
  `id` varchar(36) NOT NULL default '',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `name` varchar(255) default NULL,
  `filename` varchar(255) default NULL,
  `file_mime_type` varchar(100) default NULL,
  `parent_type` varchar(25) default NULL,
  `parent_id` varchar(36) default NULL,
  `contact_id` varchar(36) default NULL,
  `portal_flag` tinyint(1) NOT NULL default '0',
  `embed_flag` tinyint(1) NOT NULL default '0',
  `description` text,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_note_name` (`name`),
  KEY `idx_notes_parent` (`parent_id`,`parent_type`),
  KEY `idx_note_contact` (`contact_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `opportunities` (
  `id` varchar(36) NOT NULL default '',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) default NULL,
  `assigned_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  `name` varchar(50) default NULL,
  `opportunity_type` varchar(255) default NULL,
  `lead_source` varchar(50) default NULL,
  `amount` double default NULL,
  `amount_backup` varchar(25) default NULL,
  `amount_usdollar` double default NULL,
  `currency_id` varchar(36) default NULL,
  `date_closed` date default NULL,
  `next_step` varchar(100) default NULL,
  `sales_stage` varchar(25) default NULL,
  `probability` double default NULL,
  `description` text,
  `campaign_id` varchar(36) default NULL,
  PRIMARY KEY  (`id`),
  KEY `idx_opp_name` (`name`),
  KEY `idx_opp_assigned` (`assigned_user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `opportunities_audit` (
  `id` varchar(36) NOT NULL default '',
  `parent_id` varchar(36) NOT NULL default '',
  `date_created` datetime default NULL,
  `created_by` varchar(36) default NULL,
  `field_name` varchar(100) default NULL,
  `data_type` varchar(100) default NULL,
  `before_value_string` varchar(255) default NULL,
  `after_value_string` varchar(255) default NULL,
  `before_value_text` text,
  `after_value_text` text
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `opportunities_contacts` (
  `id` varchar(36) NOT NULL default '',
  `contact_id` varchar(36) default NULL,
  `opportunity_id` varchar(36) default NULL,
  `contact_role` varchar(50) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_con_opp_con` (`contact_id`),
  KEY `idx_con_opp_opp` (`opportunity_id`),
  KEY `idx_opportunities_contacts` (`opportunity_id`,`contact_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `productos` (
  `id` bigint(11) NOT NULL auto_increment,
  `categoria_id` bigint(11) default NULL,
  `nombre` varchar(255) default NULL,
  `descripcion` text,
  `costo_variable` float default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `project` (
  `id` varchar(36) NOT NULL default '',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `assigned_user_id` varchar(36) default NULL,
  `modified_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `name` varchar(50) NOT NULL default '',
  `description` text,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `project_relation` (
  `id` varchar(36) NOT NULL default '',
  `project_id` varchar(36) NOT NULL default '',
  `relation_id` varchar(36) NOT NULL default '',
  `relation_type` varchar(255) NOT NULL default '',
  `deleted` tinyint(1) NOT NULL default '0',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `project_task` (
  `id` varchar(36) NOT NULL default '',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `assigned_user_id` varchar(36) default NULL,
  `modified_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `name` varchar(50) NOT NULL default '',
  `status` varchar(255) default NULL,
  `date_due` date default NULL,
  `time_due` time default NULL,
  `date_start` date default NULL,
  `time_start` time default NULL,
  `parent_id` varchar(36) NOT NULL default '',
  `priority` varchar(255) default NULL,
  `description` text,
  `order_number` int(11) default '1',
  `task_number` int(11) default NULL,
  `depends_on_id` varchar(36) default NULL,
  `milestone_flag` varchar(255) default NULL,
  `estimated_effort` int(11) default NULL,
  `actual_effort` int(11) default NULL,
  `utilization` int(11) default '100',
  `percent_complete` int(11) default '0',
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `project_task_audit` (
  `id` varchar(36) NOT NULL default '',
  `parent_id` varchar(36) NOT NULL default '',
  `date_created` datetime default NULL,
  `created_by` varchar(36) default NULL,
  `field_name` varchar(100) default NULL,
  `data_type` varchar(100) default NULL,
  `before_value_string` varchar(255) default NULL,
  `after_value_string` varchar(255) default NULL,
  `before_value_text` text,
  `after_value_text` text
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `prospect_list_campaigns` (
  `id` varchar(36) NOT NULL default '',
  `prospect_list_id` varchar(36) default NULL,
  `campaign_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_pro_id` (`prospect_list_id`),
  KEY `idx_cam_id` (`campaign_id`),
  KEY `idx_prospect_list_campaigns` (`prospect_list_id`,`campaign_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `prospect_lists` (
  `id` varchar(36) NOT NULL default '',
  `name` varchar(50) default NULL,
  `list_type` varchar(25) default NULL,
  `date_entered` datetime default NULL,
  `date_modified` datetime default NULL,
  `modified_user_id` varchar(36) default NULL,
  `assigned_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  `description` text,
  `domain_name` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `idx_prospect_list_name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `prospect_lists_prospects` (
  `id` varchar(36) NOT NULL default '',
  `prospect_list_id` varchar(36) default NULL,
  `related_id` varchar(36) default NULL,
  `related_type` varchar(25) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_plp_pro_id` (`prospect_list_id`),
  KEY `idx_plp_rel_id` (`related_id`,`related_type`,`prospect_list_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `prospects` (
  `id` varchar(36) NOT NULL default '',
  `tracker_key` int(11) NOT NULL auto_increment,
  `deleted` tinyint(1) default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) default NULL,
  `assigned_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `salutation` varchar(5) default NULL,
  `first_name` varchar(100) default NULL,
  `last_name` varchar(100) default NULL,
  `title` varchar(25) default NULL,
  `department` varchar(255) default NULL,
  `birthdate` date default NULL,
  `do_not_call` char(3) default '0',
  `phone_home` varchar(25) default NULL,
  `phone_mobile` varchar(25) default NULL,
  `phone_work` varchar(25) default NULL,
  `phone_other` varchar(25) default NULL,
  `phone_fax` varchar(25) default NULL,
  `email1` varchar(100) default NULL,
  `email2` varchar(100) default NULL,
  `assistant` varchar(75) default NULL,
  `assistant_phone` varchar(25) default NULL,
  `email_opt_out` char(3) default '0',
  `primary_address_street` varchar(150) default NULL,
  `primary_address_city` varchar(100) default NULL,
  `primary_address_state` varchar(100) default NULL,
  `primary_address_postalcode` varchar(20) default NULL,
  `primary_address_country` varchar(100) default NULL,
  `alt_address_street` varchar(150) default NULL,
  `alt_address_city` varchar(100) default NULL,
  `alt_address_state` varchar(100) default NULL,
  `alt_address_postalcode` varchar(20) default NULL,
  `alt_address_country` varchar(100) default NULL,
  `description` text,
  `invalid_email` tinyint(1) default '0',
  `lead_id` varchar(36) default NULL,
  `account_name` varchar(150) default NULL,
  `campaign_id` varchar(36) default NULL,
  PRIMARY KEY  (`id`),
  KEY `prospect_auto_tracker_key` (`tracker_key`),
  KEY `idx_prospects_last_first` (`last_name`,`first_name`,`deleted`),
  KEY `idx_prospecs_del_last` (`last_name`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `proyecto_areas` (
  `id` bigint(11) NOT NULL auto_increment,
  `proyecto_id` bigint(11) NOT NULL default '0',
  `en_diseno` char(1) NOT NULL default '0',
  `ingreso_diseno` datetime default NULL,
  `salida_diseno` datetime default NULL,
  `estado_diseno` int(1) default '0',
  `encargado_diseno` varchar(36) default '',
  `observaciones_diseno` text,
  `en_planeamiento` char(1) NOT NULL default '0',
  `ingreso_planeamiento` datetime default NULL,
  `salida_planeamiento` datetime default NULL,
  `estado_planeamiento` int(1) default '0',
  `encargado_planeamiento` varchar(36) default '',
  `observaciones_planeamiento` text,
  `en_costos` char(1) NOT NULL default '0',
  `ingreso_costos` datetime default NULL,
  `salida_costos` datetime default NULL,
  `estado_costos` int(1) default '0',
  `encargado_costos` varchar(36) default '',
  `observaciones_costos` text,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `proyecto_estados` (
  `id` bigint(11) NOT NULL auto_increment,
  `proyecto_id` bigint(11) NOT NULL default '0',
  `estado` int(11) NOT NULL default '0',
  `fecha` datetime NOT NULL default '0000-00-00 00:00:00',
  `user_id` varchar(36) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `proyectos` (
  `id` bigint(11) NOT NULL auto_increment,
  `tipo_proyecto` int(1) NOT NULL default '0',
  `urgente` int(1) NOT NULL default '0',
  `fecha_creacion_proyecto` datetime NOT NULL default '0000-00-00 00:00:00',
  `fecha_entrega_diseno` datetime default NULL,
  `caracteristicas_entorno` varchar(200) default NULL,
  `publico_objetivo` varchar(200) default NULL,
  `dimensiones_espacio` varchar(100) default NULL,
  `nivel_seguridad` int(1) default NULL,
  `materiales` varchar(250) default NULL,
  `acabado` varchar(250) default NULL,
  `vista_frente` char(1) default '0',
  `vista_derecha` char(1) default '0',
  `vista_izquierda` char(1) default '0',
  `vista_atras` char(1) default '0',
  `vista_arriba` char(1) default '0',
  `vista_abajo` char(1) default '0',
  `observaciones` text,
  `sugerencias` text,
  `recojo` int(1) default NULL,
  `que_se_recojera` varchar(200) default NULL,
  `fecha_recojo` date default NULL,
  `hora_recojo` time default NULL,
  `lugar_recojo` varchar(200) default NULL,
  `referencia_recojo` varchar(200) default NULL,
  `quien_paga_recojo` int(1) default NULL,
  `desc_pago_recojo` varchar(100) default NULL,
  `fecha_entregar` date default NULL,
  `hora_entrega_desde` time default NULL,
  `hora_entrega_hasta` time default NULL,
  `direccion_entregar` varchar(250) default NULL,
  `ubigeo_entregar` int(6) default NULL,
  `referencia_entregar` varchar(250) default NULL,
  `valor_costo` decimal(10,2) default NULL,
  `moneda` char(1) default NULL,
  `con_igv` char(1) default NULL,
  `comision` decimal(10,2) default NULL,
  `terminado` char(1) default '0',
  `perdido` char(1) default '0',
  `ejecutivo_id` varchar(36) default NULL,
  `otro_tipo` varchar(128) default NULL,
  `tiene_cotizaciones` char(1) default '0',
  `opportunity_id` varchar(36) NOT NULL default '',
  `orden_de_trabajo` int(11) default '0',
  `empresa_vendedora` varchar(16) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `relationships` (
  `id` varchar(36) NOT NULL default '',
  `relationship_name` varchar(150) NOT NULL default '',
  `lhs_module` varchar(100) NOT NULL default '',
  `lhs_table` varchar(64) NOT NULL default '',
  `lhs_key` varchar(64) NOT NULL default '',
  `rhs_module` varchar(100) NOT NULL default '',
  `rhs_table` varchar(64) NOT NULL default '',
  `rhs_key` varchar(64) NOT NULL default '',
  `join_table` varchar(64) default NULL,
  `join_key_lhs` varchar(64) default NULL,
  `join_key_rhs` varchar(64) default NULL,
  `relationship_type` varchar(64) default NULL,
  `relationship_role_column` varchar(64) default NULL,
  `relationship_role_column_value` varchar(50) default NULL,
  `reverse` tinyint(1) default '0',
  `deleted` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_rel_name` (`relationship_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `releases` (
  `id` varchar(36) NOT NULL default '',
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) NOT NULL default '',
  `created_by` varchar(36) default NULL,
  `name` varchar(50) NOT NULL default '',
  `list_order` int(4) default NULL,
  `status` varchar(25) default NULL,
  PRIMARY KEY  (`id`),
  KEY `idx_releases` (`name`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `roles` (
  `id` varchar(36) NOT NULL default '',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) NOT NULL default '',
  `created_by` varchar(36) default NULL,
  `name` varchar(150) default NULL,
  `description` text,
  `modules` text,
  `deleted` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_role_id_del` (`id`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `roles_modules` (
  `id` varchar(36) NOT NULL default '',
  `role_id` varchar(36) default NULL,
  `module_id` varchar(36) default NULL,
  `allow` tinyint(1) default '0',
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_role_id` (`role_id`),
  KEY `idx_module_id` (`module_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `roles_users` (
  `id` varchar(36) NOT NULL default '',
  `role_id` varchar(36) default NULL,
  `user_id` varchar(36) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_ru_role_id` (`role_id`),
  KEY `idx_ru_user_id` (`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `saved_search` (
  `id` varchar(36) NOT NULL default '',
  `name` varchar(150) default NULL,
  `search_module` varchar(150) default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `assigned_user_id` varchar(36) default NULL,
  `contents` text,
  `description` text,
  PRIMARY KEY  (`id`),
  KEY `idx_desc` (`name`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `schedulers` (
  `id` varchar(36) NOT NULL default '',
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `created_by` varchar(36) default NULL,
  `modified_user_id` varchar(36) default NULL,
  `name` varchar(255) NOT NULL default '',
  `job` varchar(255) NOT NULL default '',
  `date_time_start` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_time_end` datetime default NULL,
  `job_interval` varchar(100) NOT NULL default '',
  `time_from` time default NULL,
  `time_to` time default NULL,
  `last_run` datetime default NULL,
  `status` varchar(25) default NULL,
  `catch_up` tinyint(1) default '1',
  PRIMARY KEY  (`id`),
  KEY `idx_schedule` (`date_time_start`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `schedulers_times` (
  `id` varchar(36) NOT NULL default '',
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `scheduler_id` varchar(36) NOT NULL default '',
  `execute_time` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` varchar(25) NOT NULL default 'ready',
  PRIMARY KEY  (`id`),
  KEY `idx_scheduler_id` (`scheduler_id`,`execute_time`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `servicios` (
  `id` bigint(11) NOT NULL auto_increment,
  `categoria_id` bigint(11) default NULL,
  `nombre` varchar(255) default NULL,
  `descripcion` text,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `tasks` (
  `id` varchar(36) NOT NULL default '',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `assigned_user_id` varchar(36) default NULL,
  `modified_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `name` varchar(50) default NULL,
  `status` varchar(25) default NULL,
  `date_due_flag` varchar(5) default 'on',
  `date_due` date default NULL,
  `time_due` time default NULL,
  `date_start_flag` varchar(5) default 'on',
  `date_start` date default NULL,
  `time_start` time default NULL,
  `parent_type` varchar(25) default NULL,
  `parent_id` varchar(36) default NULL,
  `contact_id` varchar(36) default NULL,
  `priority` varchar(25) default NULL,
  `description` text,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_tsk_name` (`name`),
  KEY `idx_task_con_del` (`contact_id`,`deleted`),
  KEY `idx_task_par_del` (`parent_id`,`parent_type`,`deleted`),
  KEY `idx_task_assigned` (`assigned_user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `tracker` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` varchar(36) default NULL,
  `module_name` varchar(25) default NULL,
  `item_id` varchar(36) default NULL,
  `item_summary` varchar(255) default NULL,
  `date_modified` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `upgrade_history` (
  `id` varchar(36) NOT NULL default '',
  `filename` varchar(255) default NULL,
  `md5sum` varchar(32) default NULL,
  `type` varchar(30) default NULL,
  `status` varchar(50) default NULL,
  `version` varchar(10) default NULL,
  `name` varchar(255) default NULL,
  `description` text,
  `id_name` varchar(255) default NULL,
  `manifest` text,
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `upgrade_history_md5_uk` (`md5sum`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `user_preferences` (
  `id` varchar(36) NOT NULL default '',
  `category` varchar(50) default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `assigned_user_id` varchar(36) NOT NULL default '',
  `contents` text,
  PRIMARY KEY  (`id`),
  KEY `idx_userprefnamecat` (`assigned_user_id`,`category`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `users` (
  `id` varchar(36) NOT NULL default '',
  `user_name` varchar(60) default NULL,
  `user_hash` varchar(32) default NULL,
  `authenticate_id` varchar(100) default NULL,
  `sugar_login` tinyint(1) default '1',
  `first_name` varchar(30) default NULL,
  `last_name` varchar(30) default NULL,
  `reports_to_id` varchar(36) default NULL,
  `is_admin` tinyint(1) default '0',
  `receive_notifications` tinyint(1) default '1',
  `description` text,
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `title` varchar(50) default NULL,
  `department` varchar(50) default NULL,
  `phone_home` varchar(50) default NULL,
  `phone_mobile` varchar(50) default NULL,
  `phone_work` varchar(50) default NULL,
  `phone_other` varchar(50) default NULL,
  `phone_fax` varchar(50) default NULL,
  `email1` varchar(100) default NULL,
  `email2` varchar(100) default NULL,
  `status` varchar(25) default NULL,
  `address_street` varchar(150) default NULL,
  `address_city` varchar(100) default NULL,
  `address_state` varchar(100) default NULL,
  `address_country` varchar(25) default NULL,
  `address_postalcode` varchar(9) default NULL,
  `user_preferences` text,
  `deleted` tinyint(1) NOT NULL default '0',
  `portal_only` tinyint(1) default '0',
  `employee_status` varchar(25) default NULL,
  `messenger_id` varchar(25) default NULL,
  `messenger_type` varchar(25) default NULL,
  `is_group` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `user_name_idx` (`user_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `users_feeds` (
  `user_id` varchar(36) default NULL,
  `feed_id` varchar(36) default NULL,
  `rank` int(11) default NULL,
  `date_modified` datetime default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  KEY `idx_ud_user_id` (`user_id`,`feed_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `users_last_import` (
  `id` varchar(36) NOT NULL default '',
  `assigned_user_id` varchar(36) default NULL,
  `bean_type` varchar(36) default NULL,
  `bean_id` varchar(36) default NULL,
  `deleted` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `idx_user_id` (`assigned_user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `users_signatures` (
  `id` varchar(36) NOT NULL default '',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `deleted` tinyint(1) NOT NULL default '0',
  `user_id` varchar(36) default NULL,
  `name` varchar(255) default NULL,
  `signature` text,
  `signature_html` text,
  PRIMARY KEY  (`id`),
  KEY `idx_usersig_uid` (`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `vcals` (
  `id` varchar(36) NOT NULL default '',
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime default NULL,
  `date_modified` datetime default NULL,
  `user_id` varchar(36) NOT NULL default '',
  `type` varchar(25) default NULL,
  `source` varchar(25) default NULL,
  `content` text,
  PRIMARY KEY  (`id`),
  KEY `idx_vcal` (`type`,`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `versions` (
  `id` varchar(36) NOT NULL default '',
  `deleted` tinyint(1) NOT NULL default '0',
  `date_entered` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `modified_user_id` varchar(36) NOT NULL default '',
  `created_by` varchar(36) default NULL,
  `name` varchar(255) NOT NULL default '',
  `file_version` varchar(255) NOT NULL default '',
  `db_version` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`),
  KEY `idx_version` (`name`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

