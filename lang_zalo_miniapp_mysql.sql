CREATE DATABASE IF NOT EXISTS lang_zalo_miniapp
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE lang_zalo_miniapp;

SET NAMES utf8mb4;
SET time_zone = '+07:00';

-- 1. ORGANIZATION

CREATE TABLE administrative_units (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code                VARCHAR(50) NOT NULL,
    name                VARCHAR(255) NOT NULL,
    unit_type           VARCHAR(50) NOT NULL DEFAULT 'WARD',
    address             VARCHAR(500) NULL,
    working_hours       VARCHAR(255) NULL,
    phone               VARCHAR(50) NULL,
    email               VARCHAR(255) NULL,
    area_km2            DECIMAL(10,3) NULL,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_administrative_units_code (code)
) ENGINE=InnoDB COMMENT='Administrative unit. Current project uses Phuong Lang; structure allows future expansion.';

CREATE TABLE residential_groups (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    administrative_unit_id BIGINT UNSIGNED NOT NULL,
    code                VARCHAR(50) NOT NULL,
    name                VARCHAR(255) NOT NULL,
    description         TEXT NULL,
    is_public           BOOLEAN NOT NULL DEFAULT TRUE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_residential_group_unit_code (administrative_unit_id, code),
    KEY idx_residential_group_unit (administrative_unit_id),
    CONSTRAINT fk_residential_group_unit
      FOREIGN KEY (administrative_unit_id) REFERENCES administrative_units(id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='To dan pho / residential group master data.';

CREATE TABLE departments (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    administrative_unit_id BIGINT UNSIGNED NOT NULL,
    code                VARCHAR(50) NOT NULL,
    name                VARCHAR(255) NOT NULL,
    description         TEXT NULL,
    phone               VARCHAR(50) NULL,
    email               VARCHAR(255) NULL,
    office_address      VARCHAR(500) NULL,
    is_public           BOOLEAN NOT NULL DEFAULT TRUE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_department_unit_code (administrative_unit_id, code),
    KEY idx_department_unit (administrative_unit_id),
    CONSTRAINT fk_department_unit
      FOREIGN KEY (administrative_unit_id) REFERENCES administrative_units(id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Ward offices / professional departments.';

-- 2. USERS, STAFF AND RBAC

CREATE TABLE users (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    zalo_user_id        VARCHAR(100) NULL,
    full_name           VARCHAR(255) NULL,
    phone               VARCHAR(50) NULL,
    email               VARCHAR(255) NULL,
    avatar_url          VARCHAR(1000) NULL,
    account_status      VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    last_login_at       DATETIME NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at          DATETIME NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_users_zalo_user_id (zalo_user_id),
    KEY idx_users_phone (phone),
    KEY idx_users_status (account_status)
) ENGINE=InnoDB COMMENT='Application user account. Authentication details are TBD and should be integrated with Zalo/internal identity mechanism.';

CREATE TABLE staff_profiles (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id             BIGINT UNSIGNED NOT NULL,
    department_id       BIGINT UNSIGNED NULL,
    employee_code       VARCHAR(100) NOT NULL,
    position_title      VARCHAR(255) NULL,
    public_phone        VARCHAR(50) NULL,
    public_email        VARCHAR(255) NULL,
    is_public_profile   BOOLEAN NOT NULL DEFAULT FALSE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_staff_user (user_id),
    UNIQUE KEY uk_staff_employee_code (employee_code),
    KEY idx_staff_department (department_id),
    CONSTRAINT fk_staff_user
      FOREIGN KEY (user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_staff_department
      FOREIGN KEY (department_id) REFERENCES departments(id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Authenticated ward staff profile. Employee identifier/authentication workflow is TBD.';

CREATE TABLE staff_residential_group_assignments (
    staff_profile_id    BIGINT UNSIGNED NOT NULL,
    residential_group_id BIGINT UNSIGNED NOT NULL,
    is_primary          BOOLEAN NOT NULL DEFAULT FALSE,
    assigned_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (staff_profile_id, residential_group_id),
    KEY idx_staff_group_group (residential_group_id),
    CONSTRAINT fk_staff_group_staff
      FOREIGN KEY (staff_profile_id) REFERENCES staff_profiles(id)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_staff_group_group
      FOREIGN KEY (residential_group_id) REFERENCES residential_groups(id)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Maps responsible ward staff to residential groups.';

CREATE TABLE roles (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code                VARCHAR(50) NOT NULL,
    name                VARCHAR(100) NOT NULL,
    description         VARCHAR(500) NULL,
    is_system_role      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_roles_code (code)
) ENGINE=InnoDB COMMENT='RBAC role master. Detailed permission matrix remains TBD.';

CREATE TABLE permissions (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code                VARCHAR(100) NOT NULL,
    name                VARCHAR(255) NOT NULL,
    description         VARCHAR(500) NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_permissions_code (code)
) ENGINE=InnoDB COMMENT='RBAC permission master.';

CREATE TABLE user_roles (
    user_id             BIGINT UNSIGNED NOT NULL,
    role_id             BIGINT UNSIGNED NOT NULL,
    assigned_by_user_id BIGINT UNSIGNED NULL,
    assigned_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    KEY idx_user_roles_role (role_id),
    CONSTRAINT fk_user_roles_user
      FOREIGN KEY (user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_role
      FOREIGN KEY (role_id) REFERENCES roles(id)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_assigner
      FOREIGN KEY (assigned_by_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='User-role mapping.';

CREATE TABLE role_permissions (
    role_id             BIGINT UNSIGNED NOT NULL,
    permission_id       BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    KEY idx_role_permissions_permission (permission_id),
    CONSTRAINT fk_role_permissions_role
      FOREIGN KEY (role_id) REFERENCES roles(id)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_role_permissions_permission
      FOREIGN KEY (permission_id) REFERENCES permissions(id)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Role-permission mapping.';

-- 3. PUBLIC CONTENT

CREATE TABLE content_posts (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    administrative_unit_id BIGINT UNSIGNED NOT NULL,
    post_type           VARCHAR(30) NOT NULL COMMENT 'NEWS / NOTICE / PAGE',
    title               VARCHAR(500) NOT NULL,
    summary             TEXT NULL,
    body                LONGTEXT NOT NULL,
    thumbnail_url       VARCHAR(1000) NULL,
    publish_status      VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    is_featured         BOOLEAN NOT NULL DEFAULT FALSE,
    published_at        DATETIME NULL,
    created_by_user_id  BIGINT UNSIGNED NULL,
    updated_by_user_id  BIGINT UNSIGNED NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at          DATETIME NULL,
    PRIMARY KEY (id),
    KEY idx_content_unit_type_status (administrative_unit_id, post_type, publish_status),
    KEY idx_content_published_at (published_at),
    FULLTEXT KEY ftx_content_search (title, summary, body),
    CONSTRAINT fk_content_unit
      FOREIGN KEY (administrative_unit_id) REFERENCES administrative_units(id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_content_created_by
      FOREIGN KEY (created_by_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_content_updated_by
      FOREIGN KEY (updated_by_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Public news, notices and informational pages.';

CREATE TABLE emergency_contacts (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    administrative_unit_id BIGINT UNSIGNED NOT NULL,
    contact_type        VARCHAR(50) NOT NULL COMMENT 'POLICE / FIRE / MEDICAL / ELECTRICITY / OTHER',
    name                VARCHAR(255) NOT NULL,
    phone               VARCHAR(50) NOT NULL,
    description         VARCHAR(500) NULL,
    sort_order          INT NOT NULL DEFAULT 0,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_emergency_unit_active (administrative_unit_id, is_active),
    CONSTRAINT fk_emergency_unit
      FOREIGN KEY (administrative_unit_id) REFERENCES administrative_units(id)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Emergency telephone numbers exposed to citizens.';

CREATE TABLE external_service_links (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    administrative_unit_id BIGINT UNSIGNED NOT NULL,
    category            VARCHAR(100) NULL,
    name                VARCHAR(255) NOT NULL,
    description         VARCHAR(1000) NULL,
    url                 VARCHAR(2000) NOT NULL,
    icon_url            VARCHAR(1000) NULL,
    sort_order          INT NOT NULL DEFAULT 0,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_by_user_id  BIGINT UNSIGNED NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_service_links_unit_active (administrative_unit_id, is_active),
    CONSTRAINT fk_service_links_unit
      FOREIGN KEY (administrative_unit_id) REFERENCES administrative_units(id)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_service_links_creator
      FOREIGN KEY (created_by_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Links to National Public Service Portal and other selected digital services.';

-- 4. PUBLIC ADMINISTRATIVE PROCEDURES

CREATE TABLE public_services (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    administrative_unit_id BIGINT UNSIGNED NOT NULL,
    service_code        VARCHAR(100) NOT NULL,
    name                VARCHAR(500) NOT NULL,
    description         TEXT NULL,
    required_documents_json JSON NULL COMMENT 'Structure TBD; list of required documents.',
    procedure_steps_json JSON NULL COMMENT 'Structure TBD; ordered procedure steps.',
    processing_time_text VARCHAR(500) NULL,
    fee_text            VARCHAR(500) NULL,
    responsible_department_id BIGINT UNSIGNED NULL,
    receiving_channel   VARCHAR(500) NULL,
    office_location     VARCHAR(500) NULL,
    external_service_url VARCHAR(2000) NULL,
    appointment_supported BOOLEAN NOT NULL DEFAULT FALSE,
    publish_status      VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_by_user_id  BIGINT UNSIGNED NULL,
    updated_by_user_id  BIGINT UNSIGNED NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_public_services_unit_code (administrative_unit_id, service_code),
    KEY idx_public_services_department (responsible_department_id),
    KEY idx_public_services_status (publish_status, is_active),
    FULLTEXT KEY ftx_public_services_search (name, description, processing_time_text),
    CONSTRAINT fk_public_services_unit
      FOREIGN KEY (administrative_unit_id) REFERENCES administrative_units(id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_public_services_department
      FOREIGN KEY (responsible_department_id) REFERENCES departments(id)
      ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_public_services_creator
      FOREIGN KEY (created_by_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_public_services_updater
      FOREIGN KEY (updated_by_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Administrative procedure information used for search, guidance and redirection.';

-- DU: OPTIONAL / TBD-04: appointment scope is not fully defined in SRS.
CREATE TABLE service_appointments (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    public_service_id   BIGINT UNSIGNED NOT NULL,
    user_id             BIGINT UNSIGNED NOT NULL,
    appointment_at      DATETIME NOT NULL,
    status              VARCHAR(30) NOT NULL DEFAULT 'REQUESTED',
    note                VARCHAR(1000) NULL,
    confirmation_code   VARCHAR(100) NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_appointment_confirmation_code (confirmation_code),
    KEY idx_appointment_service_time (public_service_id, appointment_at),
    KEY idx_appointment_user_time (user_id, appointment_at),
    CONSTRAINT fk_appointment_service
      FOREIGN KEY (public_service_id) REFERENCES public_services(id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_appointment_user
      FOREIGN KEY (user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='OPTIONAL: appointment requests. Exact booking workflow and slot rules are TBD.';

-- 5. AREA

CREATE TABLE population_statistics (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    administrative_unit_id BIGINT UNSIGNED NOT NULL,
    residential_group_id BIGINT UNSIGNED NULL COMMENT 'NULL means ward-level aggregate.',
    reference_date      DATE NOT NULL,
    households_count    INT UNSIGNED NULL,
    population_count    INT UNSIGNED NULL,
    male_count          INT UNSIGNED NULL,
    female_count        INT UNSIGNED NULL,
    age_distribution_json JSON NULL COMMENT 'Aggregated age-group counts only; no person-level records.',
    source_note         VARCHAR(1000) NULL,
    is_public           BOOLEAN NOT NULL DEFAULT FALSE,
    approved_by_user_id BIGINT UNSIGNED NULL,
    approved_at         DATETIME NULL,
    created_by_user_id  BIGINT UNSIGNED NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_population_scope_date (administrative_unit_id, residential_group_id, reference_date),
    KEY idx_population_group_date (residential_group_id, reference_date),
    KEY idx_population_public (is_public, reference_date),
    CONSTRAINT fk_population_unit
      FOREIGN KEY (administrative_unit_id) REFERENCES administrative_units(id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_population_group
      FOREIGN KEY (residential_group_id) REFERENCES residential_groups(id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_population_approver
      FOREIGN KEY (approved_by_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_population_creator
      FOREIGN KEY (created_by_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Aggregated population statistics approved for public display.';

-- 6. LOCATIONS

CREATE TABLE location_categories (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code                VARCHAR(50) NOT NULL,
    name                VARCHAR(255) NOT NULL,
    icon_key            VARCHAR(100) NULL,
    sort_order          INT NOT NULL DEFAULT 0,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id),
    UNIQUE KEY uk_location_categories_code (code)
) ENGINE=InnoDB COMMENT='Map location categories.';

CREATE TABLE map_locations (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    administrative_unit_id BIGINT UNSIGNED NOT NULL,
    residential_group_id BIGINT UNSIGNED NULL,
    category_id         BIGINT UNSIGNED NULL,
    name                VARCHAR(500) NOT NULL,
    description         TEXT NULL,
    address             VARCHAR(1000) NULL,
    latitude            DECIMAL(10,7) NOT NULL,
    longitude           DECIMAL(10,7) NOT NULL,
    external_place_id   VARCHAR(255) NULL,
    image_url           VARCHAR(1000) NULL,
    is_public           BOOLEAN NOT NULL DEFAULT TRUE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_by_user_id  BIGINT UNSIGNED NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_map_location_unit_category (administrative_unit_id, category_id, is_active),
    KEY idx_map_location_group (residential_group_id),
    KEY idx_map_location_lat_lng (latitude, longitude),
    CONSTRAINT fk_map_location_unit
      FOREIGN KEY (administrative_unit_id) REFERENCES administrative_units(id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_map_location_group
      FOREIGN KEY (residential_group_id) REFERENCES residential_groups(id)
      ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_map_location_category
      FOREIGN KEY (category_id) REFERENCES location_categories(id)
      ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_map_location_creator
      FOREIGN KEY (created_by_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Public map points managed by administrators.';

CREATE TABLE bottlenecks (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    administrative_unit_id BIGINT UNSIGNED NOT NULL,
    residential_group_id BIGINT UNSIGNED NULL,
    map_location_id     BIGINT UNSIGNED NULL,
    title               VARCHAR(500) NOT NULL,
    description         TEXT NULL,
    severity            VARCHAR(30) NULL,
    status              VARCHAR(30) NOT NULL DEFAULT 'OPEN',
    observed_at         DATETIME NULL,
    resolved_at         DATETIME NULL,
    is_public           BOOLEAN NOT NULL DEFAULT FALSE,
    created_by_user_id  BIGINT UNSIGNED NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_bottleneck_unit_status (administrative_unit_id, status),
    KEY idx_bottleneck_group (residential_group_id),
    CONSTRAINT fk_bottleneck_unit
      FOREIGN KEY (administrative_unit_id) REFERENCES administrative_units(id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_bottleneck_group
      FOREIGN KEY (residential_group_id) REFERENCES residential_groups(id)
      ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_bottleneck_location
      FOREIGN KEY (map_location_id) REFERENCES map_locations(id)
      ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_bottleneck_creator
      FOREIGN KEY (created_by_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Area bottleneck data maintained by administrators.';

-- 7. FEEDBACK
CREATE TABLE feedback_statuses (
    code                VARCHAR(30) NOT NULL,
    name                VARCHAR(100) NOT NULL,
    description         VARCHAR(500) NULL,
    sort_order          INT NOT NULL DEFAULT 0,
    is_terminal         BOOLEAN NOT NULL DEFAULT FALSE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (code)
) ENGINE=InnoDB COMMENT='Configurable feedback workflow statuses. Seed values are assumptions pending workflow confirmation.';

CREATE TABLE feedback_reports (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tracking_code       VARCHAR(50) NOT NULL,
    administrative_unit_id BIGINT UNSIGNED NOT NULL,
    citizen_user_id     BIGINT UNSIGNED NOT NULL,
    subject             VARCHAR(500) NULL,
    content             TEXT NOT NULL,
    metadata_json       JSON NULL COMMENT 'Additional required data fields are TBD; avoid unnecessary PII.',
    status_code         VARCHAR(30) NOT NULL DEFAULT 'NEW',
    assigned_department_id BIGINT UNSIGNED NULL,
    assigned_staff_user_id BIGINT UNSIGNED NULL,
    is_private          BOOLEAN NOT NULL DEFAULT TRUE,
    submitted_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_status_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at           DATETIME NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_feedback_tracking_code (tracking_code),
    KEY idx_feedback_citizen_submitted (citizen_user_id, submitted_at),
    KEY idx_feedback_status_submitted (status_code, submitted_at),
    KEY idx_feedback_department_status (assigned_department_id, status_code),
    KEY idx_feedback_staff_status (assigned_staff_user_id, status_code),
    CONSTRAINT fk_feedback_unit
      FOREIGN KEY (administrative_unit_id) REFERENCES administrative_units(id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_feedback_citizen
      FOREIGN KEY (citizen_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_feedback_status
      FOREIGN KEY (status_code) REFERENCES feedback_statuses(code)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_feedback_department
      FOREIGN KEY (assigned_department_id) REFERENCES departments(id)
      ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_feedback_staff
      FOREIGN KEY (assigned_staff_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Private citizen feedback. Application authorization must restrict access to owner + authorized staff only.';

CREATE TABLE feedback_attachments (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    feedback_report_id  BIGINT UNSIGNED NOT NULL,
    file_name           VARCHAR(500) NULL,
    file_url            VARCHAR(2000) NOT NULL,
    mime_type           VARCHAR(100) NULL,
    file_size_bytes     BIGINT UNSIGNED NULL,
    uploaded_by_user_id BIGINT UNSIGNED NOT NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_feedback_attachment_report (feedback_report_id),
    CONSTRAINT fk_feedback_attachment_report
      FOREIGN KEY (feedback_report_id) REFERENCES feedback_reports(id)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_feedback_attachment_uploader
      FOREIGN KEY (uploaded_by_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Image/file attachments. File type, size and count limits are TBD.';

CREATE TABLE feedback_responses (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    feedback_report_id  BIGINT UNSIGNED NOT NULL,
    author_user_id      BIGINT UNSIGNED NOT NULL,
    response_text       TEXT NOT NULL,
    is_official_response BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_feedback_response_report_time (feedback_report_id, created_at),
    CONSTRAINT fk_feedback_response_report
      FOREIGN KEY (feedback_report_id) REFERENCES feedback_reports(id)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_feedback_response_author
      FOREIGN KEY (author_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Ward staff responses to a citizen feedback report.';

-- 8. STAFF ANNOUNCEMENTS

CREATE TABLE internal_announcements (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    administrative_unit_id BIGINT UNSIGNED NOT NULL,
    title               VARCHAR(500) NOT NULL,
    body                LONGTEXT NOT NULL,
    publish_status      VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    target_scope_json   JSON NULL COMMENT 'Detailed targeting/permission model is TBD and confidential in source documentation.',
    published_at        DATETIME NULL,
    expires_at          DATETIME NULL,
    created_by_user_id  BIGINT UNSIGNED NOT NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_internal_announcement_unit_status (administrative_unit_id, publish_status, published_at),
    CONSTRAINT fk_internal_announcement_unit
      FOREIGN KEY (administrative_unit_id) REFERENCES administrative_units(id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_internal_announcement_creator
      FOREIGN KEY (created_by_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Staff-only internal operational announcements.';

-- 9. LEGAL LIBRARY

CREATE TABLE legal_documents (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    document_number     VARCHAR(255) NULL,
    title               VARCHAR(1000) NOT NULL,
    issuer              VARCHAR(500) NULL,
    document_type       VARCHAR(255) NULL,
    issued_date         DATE NULL,
    effective_date      DATE NULL,
    expiry_date         DATE NULL,
    summary             TEXT NULL,
    source_url          VARCHAR(2000) NULL,
    source_external_id  VARCHAR(255) NULL,
    sync_source         VARCHAR(255) NULL,
    last_synced_at      DATETIME NULL,
    publish_status      VARCHAR(30) NOT NULL DEFAULT 'PUBLISHED',
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_legal_document_number (document_number),
    KEY idx_legal_effective_date (effective_date),
    FULLTEXT KEY ftx_legal_document_search (title, summary)
) ENGINE=InnoDB COMMENT='Legal library metadata / synchronized legal sources used for public lookup and AI retrieval. Detailed RAG design is TBD.';

-- 10. EXTERNAL INTEGRATIONS

CREATE TABLE integration_providers (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    provider_type       VARCHAR(50) NOT NULL COMMENT 'WEATHER / MAP / LEGAL_DATA / PUBLIC_SERVICE / OTHER',
    name                VARCHAR(255) NOT NULL,
    base_url            VARCHAR(2000) NULL,
    credential_ref      VARCHAR(500) NULL COMMENT 'Reference to external secret manager/env var; never store raw secrets.',
    config_json         JSON NULL,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_integration_provider_type_name (provider_type, name)
) ENGINE=InnoDB COMMENT='External API/service configuration without raw credentials.';

CREATE TABLE integration_logs (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    integration_provider_id BIGINT UNSIGNED NOT NULL,
    operation_name      VARCHAR(255) NULL,
    request_id          VARCHAR(255) NULL,
    http_status         SMALLINT UNSIGNED NULL,
    response_time_ms    INT UNSIGNED NULL,
    is_success          BOOLEAN NOT NULL DEFAULT FALSE,
    error_code          VARCHAR(255) NULL,
    error_message       VARCHAR(2000) NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_integration_log_provider_time (integration_provider_id, created_at),
    KEY idx_integration_log_success_time (is_success, created_at),
    CONSTRAINT fk_integration_log_provider
      FOREIGN KEY (integration_provider_id) REFERENCES integration_providers(id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Recommended integration monitoring log; retention policy is TBD.';

CREATE TABLE weather_cache (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    administrative_unit_id BIGINT UNSIGNED NOT NULL,
    observed_at         DATETIME NOT NULL,
    expires_at          DATETIME NULL,
    temperature_c       DECIMAL(5,2) NULL,
    weather_condition   VARCHAR(255) NULL,
    payload_json        JSON NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_weather_unit_observed (administrative_unit_id, observed_at),
    KEY idx_weather_expires (expires_at),
    CONSTRAINT fk_weather_unit
      FOREIGN KEY (administrative_unit_id) REFERENCES administrative_units(id)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Optional weather API cache.';

-- ============================================================================
-- 11. AUDIT TRAIL (RECOMMENDED)
-- ============================================================================

CREATE TABLE audit_logs (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    actor_user_id       BIGINT UNSIGNED NULL,
    action              VARCHAR(100) NOT NULL,
    entity_type         VARCHAR(100) NOT NULL,
    entity_id           VARCHAR(100) NULL,
    old_data_json       JSON NULL,
    new_data_json       JSON NULL,
    ip_address          VARCHAR(64) NULL,
    user_agent          VARCHAR(1000) NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_audit_actor_time (actor_user_id, created_at),
    KEY idx_audit_entity_time (entity_type, entity_id, created_at),
    CONSTRAINT fk_audit_actor
      FOREIGN KEY (actor_user_id) REFERENCES users(id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Recommended admin audit trail. Retention/security policy remains TBD.';

-- 12. BASELINE SEED DATA

INSERT INTO administrative_units (code, name, unit_type)
VALUES ('LANG', 'Phường Láng', 'WARD')
ON DUPLICATE KEY UPDATE name = VALUES(name), unit_type = VALUES(unit_type);

INSERT INTO roles (code, name, description, is_system_role) VALUES
('CITIZEN', 'Người dân', 'Public Mini App user.', TRUE),
('STAFF',   'Cán bộ phường', 'Authenticated ward staff.', TRUE),
('ADMIN',   'Quản trị viên', 'Internal content/data administrator.', TRUE)
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

-- Placeholder workflow values only. Replace/extend after TBD-07 is confirmed.
INSERT INTO feedback_statuses (code, name, description, sort_order, is_terminal) VALUES
('NEW',         'Mới tiếp nhận',       'Initial submitted state.', 10, FALSE),
('IN_PROGRESS', 'Đang xử lý',          'Assigned/being processed.', 20, FALSE),
('RESPONDED',   'Đã trả lời',          'Official response has been provided.', 30, FALSE),
('CLOSED',      'Đã đóng',             'Processing completed.', 40, TRUE),
('REJECTED',    'Không tiếp nhận',     'Rejected according to approved business rules.', 50, TRUE)
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description), sort_order = VALUES(sort_order), is_terminal = VALUES(is_terminal);

INSERT INTO location_categories (code, name, sort_order) VALUES
('GOVERNMENT', 'Cơ quan hành chính', 10),
('PUBLIC',     'Địa điểm công cộng', 20),
('LANDMARK',   'Địa danh', 30),
('UTILITY',    'Điểm tiện ích', 40),
('OTHER',      'Khác', 99)
ON DUPLICATE KEY UPDATE name = VALUES(name), sort_order = VALUES(sort_order);



-- CREATE OR REPLACE VIEW vw_public_residential_group_statistics AS
-- SELECT
--     ps.id,
--     au.code AS administrative_unit_code,
--     au.name AS administrative_unit_name,
--     rg.code AS residential_group_code,
--     rg.name AS residential_group_name,
--     ps.reference_date,
--     ps.households_count,
--     ps.population_count,
--     ps.male_count,
--     ps.female_count,
--     ps.age_distribution_json,
--     ps.source_note
-- FROM population_statistics ps
-- JOIN administrative_units au ON au.id = ps.administrative_unit_id
-- LEFT JOIN residential_groups rg ON rg.id = ps.residential_group_id
-- WHERE ps.is_public = TRUE;

-- CREATE OR REPLACE VIEW vw_feedback_timeline AS
-- SELECT
--     fr.id AS feedback_report_id,
--     fr.tracking_code,
--     fr.citizen_user_id,
--     fr.status_code,
--     fr.submitted_at,
--     r.id AS response_id,
--     r.author_user_id,
--     r.response_text,
--     r.created_at AS response_created_at
-- FROM feedback_reports fr
-- LEFT JOIN feedback_responses r ON r.feedback_report_id = fr.id;