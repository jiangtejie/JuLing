--
-- PostgreSQL database dump
--

\restrict FJGYPIQk1taL7xtcr8JcvdWxTEiT6YBvMnkRfM5hH2D4xtOdH8eTgbxLea1oO5S

-- Dumped from database version 15.18 (Debian 15.18-1.pgdg13+1)
-- Dumped by pg_dump version 15.19

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--



--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--



--
-- Name: ifnull(anycompatible, anycompatible); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ifnull(anycompatible, anycompatible) RETURNS anycompatible
    LANGUAGE sql IMMUTABLE
    AS $_$ SELECT COALESCE($1, $2) $_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: act_evt_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_evt_log (
    log_nr_ integer NOT NULL,
    type_ character varying(64),
    proc_def_id_ character varying(64),
    proc_inst_id_ character varying(64),
    execution_id_ character varying(64),
    task_id_ character varying(64),
    time_stamp_ timestamp without time zone NOT NULL,
    user_id_ character varying(255),
    data_ bytea,
    lock_owner_ character varying(255),
    lock_time_ timestamp without time zone,
    is_processed_ smallint DEFAULT 0
);


--
-- Name: act_evt_log_log_nr__seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.act_evt_log_log_nr__seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: act_evt_log_log_nr__seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.act_evt_log_log_nr__seq OWNED BY public.act_evt_log.log_nr_;


--
-- Name: act_ge_bytearray; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ge_bytearray (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    name_ character varying(255),
    deployment_id_ character varying(64),
    bytes_ bytea,
    generated_ boolean
);


--
-- Name: act_ge_property; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ge_property (
    name_ character varying(64) NOT NULL,
    value_ character varying(300),
    rev_ integer
);


--
-- Name: act_hi_actinst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_hi_actinst (
    id_ character varying(64) NOT NULL,
    rev_ integer DEFAULT 1,
    proc_def_id_ character varying(64) NOT NULL,
    proc_inst_id_ character varying(64) NOT NULL,
    execution_id_ character varying(64) NOT NULL,
    act_id_ character varying(255) NOT NULL,
    task_id_ character varying(64),
    call_proc_inst_id_ character varying(64),
    act_name_ character varying(255),
    act_type_ character varying(255) NOT NULL,
    assignee_ character varying(255),
    completed_by_ character varying(255),
    start_time_ timestamp without time zone NOT NULL,
    end_time_ timestamp without time zone,
    transaction_order_ integer,
    duration_ bigint,
    delete_reason_ character varying(4000),
    tenant_id_ character varying(255) DEFAULT ''::character varying
);


--
-- Name: act_hi_attachment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_hi_attachment (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    user_id_ character varying(255),
    name_ character varying(255),
    description_ character varying(4000),
    type_ character varying(255),
    task_id_ character varying(64),
    proc_inst_id_ character varying(64),
    url_ character varying(4000),
    content_id_ character varying(64),
    time_ timestamp without time zone
);


--
-- Name: act_hi_comment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_hi_comment (
    id_ character varying(64) NOT NULL,
    type_ character varying(255),
    time_ timestamp without time zone NOT NULL,
    user_id_ character varying(255),
    task_id_ character varying(64),
    proc_inst_id_ character varying(64),
    action_ character varying(255),
    message_ character varying(4000),
    full_msg_ bytea
);


--
-- Name: act_hi_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_hi_detail (
    id_ character varying(64) NOT NULL,
    type_ character varying(255) NOT NULL,
    proc_inst_id_ character varying(64),
    execution_id_ character varying(64),
    task_id_ character varying(64),
    act_inst_id_ character varying(64),
    name_ character varying(255) NOT NULL,
    var_type_ character varying(64),
    rev_ integer,
    time_ timestamp without time zone NOT NULL,
    bytearray_id_ character varying(64),
    double_ double precision,
    long_ bigint,
    text_ character varying(4000),
    text2_ character varying(4000)
);


--
-- Name: act_hi_entitylink; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_hi_entitylink (
    id_ character varying(64) NOT NULL,
    link_type_ character varying(255),
    create_time_ timestamp without time zone,
    scope_id_ character varying(255),
    sub_scope_id_ character varying(255),
    scope_type_ character varying(255),
    scope_definition_id_ character varying(255),
    parent_element_id_ character varying(255),
    ref_scope_id_ character varying(255),
    ref_scope_type_ character varying(255),
    ref_scope_definition_id_ character varying(255),
    root_scope_id_ character varying(255),
    root_scope_type_ character varying(255),
    hierarchy_type_ character varying(255)
);


--
-- Name: act_hi_identitylink; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_hi_identitylink (
    id_ character varying(64) NOT NULL,
    group_id_ character varying(255),
    type_ character varying(255),
    user_id_ character varying(255),
    task_id_ character varying(64),
    create_time_ timestamp without time zone,
    proc_inst_id_ character varying(64),
    scope_id_ character varying(255),
    sub_scope_id_ character varying(255),
    scope_type_ character varying(255),
    scope_definition_id_ character varying(255)
);


--
-- Name: act_hi_procinst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_hi_procinst (
    id_ character varying(64) NOT NULL,
    rev_ integer DEFAULT 1,
    proc_inst_id_ character varying(64) NOT NULL,
    business_key_ character varying(255),
    proc_def_id_ character varying(64) NOT NULL,
    start_time_ timestamp without time zone NOT NULL,
    end_time_ timestamp without time zone,
    duration_ bigint,
    start_user_id_ character varying(255),
    start_act_id_ character varying(255),
    end_act_id_ character varying(255),
    super_process_instance_id_ character varying(64),
    delete_reason_ character varying(4000),
    tenant_id_ character varying(255) DEFAULT ''::character varying,
    name_ character varying(255),
    callback_id_ character varying(255),
    callback_type_ character varying(255),
    reference_id_ character varying(255),
    reference_type_ character varying(255),
    propagated_stage_inst_id_ character varying(255),
    business_status_ character varying(255),
    end_user_id_ character varying(255),
    state_ character varying(255)
);


--
-- Name: act_hi_taskinst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_hi_taskinst (
    id_ character varying(64) NOT NULL,
    rev_ integer DEFAULT 1,
    proc_def_id_ character varying(64),
    task_def_id_ character varying(64),
    task_def_key_ character varying(255),
    proc_inst_id_ character varying(64),
    execution_id_ character varying(64),
    scope_id_ character varying(255),
    sub_scope_id_ character varying(255),
    scope_type_ character varying(255),
    scope_definition_id_ character varying(255),
    propagated_stage_inst_id_ character varying(255),
    state_ character varying(255),
    name_ character varying(255),
    parent_task_id_ character varying(64),
    description_ character varying(4000),
    owner_ character varying(255),
    assignee_ character varying(255),
    start_time_ timestamp without time zone NOT NULL,
    in_progress_time_ timestamp without time zone,
    in_progress_started_by_ character varying(255),
    claim_time_ timestamp without time zone,
    claimed_by_ character varying(255),
    suspended_time_ timestamp without time zone,
    suspended_by_ character varying(255),
    end_time_ timestamp without time zone,
    completed_by_ character varying(255),
    duration_ bigint,
    delete_reason_ character varying(4000),
    priority_ integer,
    in_progress_due_date_ timestamp without time zone,
    due_date_ timestamp without time zone,
    form_key_ character varying(255),
    category_ character varying(255),
    tenant_id_ character varying(255) DEFAULT ''::character varying,
    last_updated_time_ timestamp without time zone
);


--
-- Name: act_hi_tsk_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_hi_tsk_log (
    id_ integer NOT NULL,
    type_ character varying(64),
    task_id_ character varying(64) NOT NULL,
    time_stamp_ timestamp without time zone NOT NULL,
    user_id_ character varying(255),
    data_ character varying(4000),
    execution_id_ character varying(64),
    proc_inst_id_ character varying(64),
    proc_def_id_ character varying(64),
    scope_id_ character varying(255),
    scope_definition_id_ character varying(255),
    sub_scope_id_ character varying(255),
    scope_type_ character varying(255),
    tenant_id_ character varying(255) DEFAULT ''::character varying
);


--
-- Name: act_hi_tsk_log_id__seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.act_hi_tsk_log_id__seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: act_hi_tsk_log_id__seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.act_hi_tsk_log_id__seq OWNED BY public.act_hi_tsk_log.id_;


--
-- Name: act_hi_varinst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_hi_varinst (
    id_ character varying(64) NOT NULL,
    rev_ integer DEFAULT 1,
    proc_inst_id_ character varying(64),
    execution_id_ character varying(64),
    task_id_ character varying(64),
    name_ character varying(255) NOT NULL,
    var_type_ character varying(100),
    scope_id_ character varying(255),
    sub_scope_id_ character varying(255),
    scope_type_ character varying(255),
    bytearray_id_ character varying(64),
    double_ double precision,
    long_ bigint,
    text_ character varying(4000),
    text2_ character varying(4000),
    meta_info_ character varying(4000),
    create_time_ timestamp without time zone,
    last_updated_time_ timestamp without time zone
);


--
-- Name: act_id_bytearray; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_id_bytearray (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    name_ character varying(255),
    bytes_ bytea
);


--
-- Name: act_id_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_id_group (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    name_ character varying(255),
    type_ character varying(255)
);


--
-- Name: act_id_info; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_id_info (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    user_id_ character varying(64),
    type_ character varying(64),
    key_ character varying(255),
    value_ character varying(255),
    password_ bytea,
    parent_id_ character varying(255)
);


--
-- Name: act_id_membership; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_id_membership (
    user_id_ character varying(64) NOT NULL,
    group_id_ character varying(64) NOT NULL
);


--
-- Name: act_id_priv; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_id_priv (
    id_ character varying(64) NOT NULL,
    name_ character varying(255) NOT NULL
);


--
-- Name: act_id_priv_mapping; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_id_priv_mapping (
    id_ character varying(64) NOT NULL,
    priv_id_ character varying(64) NOT NULL,
    user_id_ character varying(255),
    group_id_ character varying(255)
);


--
-- Name: act_id_property; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_id_property (
    name_ character varying(64) NOT NULL,
    value_ character varying(300),
    rev_ integer
);


--
-- Name: act_id_token; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_id_token (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    token_value_ character varying(255),
    token_date_ timestamp without time zone,
    ip_address_ character varying(255),
    user_agent_ character varying(255),
    user_id_ character varying(255),
    token_data_ character varying(2000)
);


--
-- Name: act_id_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_id_user (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    first_ character varying(255),
    last_ character varying(255),
    display_name_ character varying(255),
    email_ character varying(255),
    pwd_ character varying(255),
    picture_id_ character varying(64),
    tenant_id_ character varying(255) DEFAULT ''::character varying
);


--
-- Name: act_procdef_info; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_procdef_info (
    id_ character varying(64) NOT NULL,
    proc_def_id_ character varying(64) NOT NULL,
    rev_ integer,
    info_json_id_ character varying(64)
);


--
-- Name: act_re_deployment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_re_deployment (
    id_ character varying(64) NOT NULL,
    name_ character varying(255),
    category_ character varying(255),
    key_ character varying(255),
    tenant_id_ character varying(255) DEFAULT ''::character varying,
    deploy_time_ timestamp without time zone,
    derived_from_ character varying(64),
    derived_from_root_ character varying(64),
    parent_deployment_id_ character varying(255),
    engine_version_ character varying(255)
);


--
-- Name: act_re_model; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_re_model (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    name_ character varying(255),
    key_ character varying(255),
    category_ character varying(255),
    create_time_ timestamp without time zone,
    last_update_time_ timestamp without time zone,
    version_ integer,
    meta_info_ character varying(4000),
    deployment_id_ character varying(64),
    editor_source_value_id_ character varying(64),
    editor_source_extra_value_id_ character varying(64),
    tenant_id_ character varying(255) DEFAULT ''::character varying
);


--
-- Name: act_re_procdef; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_re_procdef (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    category_ character varying(255),
    name_ character varying(255),
    key_ character varying(255) NOT NULL,
    version_ integer NOT NULL,
    deployment_id_ character varying(64),
    resource_name_ character varying(4000),
    dgrm_resource_name_ character varying(4000),
    description_ character varying(4000),
    has_start_form_key_ boolean,
    has_graphical_notation_ boolean,
    suspension_state_ integer,
    tenant_id_ character varying(255) DEFAULT ''::character varying,
    derived_from_ character varying(64),
    derived_from_root_ character varying(64),
    derived_version_ integer DEFAULT 0 NOT NULL,
    engine_version_ character varying(255)
);


--
-- Name: act_ru_actinst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ru_actinst (
    id_ character varying(64) NOT NULL,
    rev_ integer DEFAULT 1,
    proc_def_id_ character varying(64) NOT NULL,
    proc_inst_id_ character varying(64) NOT NULL,
    execution_id_ character varying(64) NOT NULL,
    act_id_ character varying(255) NOT NULL,
    task_id_ character varying(64),
    call_proc_inst_id_ character varying(64),
    act_name_ character varying(255),
    act_type_ character varying(255) NOT NULL,
    assignee_ character varying(255),
    completed_by_ character varying(255),
    start_time_ timestamp without time zone NOT NULL,
    end_time_ timestamp without time zone,
    duration_ bigint,
    transaction_order_ integer,
    delete_reason_ character varying(4000),
    tenant_id_ character varying(255) DEFAULT ''::character varying
);


--
-- Name: act_ru_deadletter_job; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ru_deadletter_job (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    category_ character varying(255),
    type_ character varying(255) NOT NULL,
    exclusive_ boolean,
    execution_id_ character varying(64),
    process_instance_id_ character varying(64),
    proc_def_id_ character varying(64),
    element_id_ character varying(255),
    element_name_ character varying(255),
    scope_id_ character varying(255),
    sub_scope_id_ character varying(255),
    scope_type_ character varying(255),
    scope_definition_id_ character varying(255),
    correlation_id_ character varying(255),
    exception_stack_id_ character varying(64),
    exception_msg_ character varying(4000),
    duedate_ timestamp without time zone,
    repeat_ character varying(255),
    handler_type_ character varying(255),
    handler_cfg_ character varying(4000),
    custom_values_id_ character varying(64),
    create_time_ timestamp without time zone,
    tenant_id_ character varying(255) DEFAULT ''::character varying
);


--
-- Name: act_ru_entitylink; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ru_entitylink (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    create_time_ timestamp without time zone,
    link_type_ character varying(255),
    scope_id_ character varying(255),
    sub_scope_id_ character varying(255),
    scope_type_ character varying(255),
    scope_definition_id_ character varying(255),
    parent_element_id_ character varying(255),
    ref_scope_id_ character varying(255),
    ref_scope_type_ character varying(255),
    ref_scope_definition_id_ character varying(255),
    root_scope_id_ character varying(255),
    root_scope_type_ character varying(255),
    hierarchy_type_ character varying(255)
);


--
-- Name: act_ru_event_subscr; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ru_event_subscr (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    event_type_ character varying(255) NOT NULL,
    event_name_ character varying(255),
    execution_id_ character varying(64),
    proc_inst_id_ character varying(64),
    activity_id_ character varying(64),
    configuration_ character varying(255),
    created_ timestamp without time zone NOT NULL,
    proc_def_id_ character varying(64),
    sub_scope_id_ character varying(64),
    scope_id_ character varying(64),
    scope_definition_id_ character varying(64),
    scope_definition_key_ character varying(255),
    scope_type_ character varying(64),
    lock_time_ timestamp without time zone,
    lock_owner_ character varying(255),
    tenant_id_ character varying(255) DEFAULT ''::character varying
);


--
-- Name: act_ru_execution; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ru_execution (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    proc_inst_id_ character varying(64),
    business_key_ character varying(255),
    parent_id_ character varying(64),
    proc_def_id_ character varying(64),
    super_exec_ character varying(64),
    root_proc_inst_id_ character varying(64),
    act_id_ character varying(255),
    is_active_ boolean,
    is_concurrent_ boolean,
    is_scope_ boolean,
    is_event_scope_ boolean,
    is_mi_root_ boolean,
    suspension_state_ integer,
    cached_ent_state_ integer,
    tenant_id_ character varying(255) DEFAULT ''::character varying,
    name_ character varying(255),
    start_act_id_ character varying(255),
    start_time_ timestamp without time zone,
    start_user_id_ character varying(255),
    lock_time_ timestamp without time zone,
    lock_owner_ character varying(255),
    is_count_enabled_ boolean,
    evt_subscr_count_ integer,
    task_count_ integer,
    job_count_ integer,
    timer_job_count_ integer,
    susp_job_count_ integer,
    deadletter_job_count_ integer,
    external_worker_job_count_ integer,
    var_count_ integer,
    id_link_count_ integer,
    callback_id_ character varying(255),
    callback_type_ character varying(255),
    reference_id_ character varying(255),
    reference_type_ character varying(255),
    propagated_stage_inst_id_ character varying(255),
    business_status_ character varying(255)
);


--
-- Name: act_ru_external_job; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ru_external_job (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    category_ character varying(255),
    type_ character varying(255) NOT NULL,
    lock_exp_time_ timestamp without time zone,
    lock_owner_ character varying(255),
    exclusive_ boolean,
    execution_id_ character varying(64),
    process_instance_id_ character varying(64),
    proc_def_id_ character varying(64),
    element_id_ character varying(255),
    element_name_ character varying(255),
    scope_id_ character varying(255),
    sub_scope_id_ character varying(255),
    scope_type_ character varying(255),
    scope_definition_id_ character varying(255),
    correlation_id_ character varying(255),
    retries_ integer,
    exception_stack_id_ character varying(64),
    exception_msg_ character varying(4000),
    duedate_ timestamp without time zone,
    repeat_ character varying(255),
    handler_type_ character varying(255),
    handler_cfg_ character varying(4000),
    custom_values_id_ character varying(64),
    create_time_ timestamp without time zone,
    tenant_id_ character varying(255) DEFAULT ''::character varying
);


--
-- Name: act_ru_history_job; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ru_history_job (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    lock_exp_time_ timestamp without time zone,
    lock_owner_ character varying(255),
    retries_ integer,
    exception_stack_id_ character varying(64),
    exception_msg_ character varying(4000),
    handler_type_ character varying(255),
    handler_cfg_ character varying(4000),
    custom_values_id_ character varying(64),
    adv_handler_cfg_id_ character varying(64),
    create_time_ timestamp without time zone,
    scope_type_ character varying(255),
    tenant_id_ character varying(255) DEFAULT ''::character varying
);


--
-- Name: act_ru_identitylink; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ru_identitylink (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    group_id_ character varying(255),
    type_ character varying(255),
    user_id_ character varying(255),
    task_id_ character varying(64),
    proc_inst_id_ character varying(64),
    proc_def_id_ character varying(64),
    scope_id_ character varying(255),
    sub_scope_id_ character varying(255),
    scope_type_ character varying(255),
    scope_definition_id_ character varying(255)
);


--
-- Name: act_ru_job; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ru_job (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    category_ character varying(255),
    type_ character varying(255) NOT NULL,
    lock_exp_time_ timestamp without time zone,
    lock_owner_ character varying(255),
    exclusive_ boolean,
    execution_id_ character varying(64),
    process_instance_id_ character varying(64),
    proc_def_id_ character varying(64),
    element_id_ character varying(255),
    element_name_ character varying(255),
    scope_id_ character varying(255),
    sub_scope_id_ character varying(255),
    scope_type_ character varying(255),
    scope_definition_id_ character varying(255),
    correlation_id_ character varying(255),
    retries_ integer,
    exception_stack_id_ character varying(64),
    exception_msg_ character varying(4000),
    duedate_ timestamp without time zone,
    repeat_ character varying(255),
    handler_type_ character varying(255),
    handler_cfg_ character varying(4000),
    custom_values_id_ character varying(64),
    create_time_ timestamp without time zone,
    tenant_id_ character varying(255) DEFAULT ''::character varying
);


--
-- Name: act_ru_suspended_job; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ru_suspended_job (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    category_ character varying(255),
    type_ character varying(255) NOT NULL,
    exclusive_ boolean,
    execution_id_ character varying(64),
    process_instance_id_ character varying(64),
    proc_def_id_ character varying(64),
    element_id_ character varying(255),
    element_name_ character varying(255),
    scope_id_ character varying(255),
    sub_scope_id_ character varying(255),
    scope_type_ character varying(255),
    scope_definition_id_ character varying(255),
    correlation_id_ character varying(255),
    retries_ integer,
    exception_stack_id_ character varying(64),
    exception_msg_ character varying(4000),
    duedate_ timestamp without time zone,
    repeat_ character varying(255),
    handler_type_ character varying(255),
    handler_cfg_ character varying(4000),
    custom_values_id_ character varying(64),
    create_time_ timestamp without time zone,
    tenant_id_ character varying(255) DEFAULT ''::character varying
);


--
-- Name: act_ru_task; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ru_task (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    execution_id_ character varying(64),
    proc_inst_id_ character varying(64),
    proc_def_id_ character varying(64),
    task_def_id_ character varying(64),
    scope_id_ character varying(255),
    sub_scope_id_ character varying(255),
    scope_type_ character varying(255),
    scope_definition_id_ character varying(255),
    propagated_stage_inst_id_ character varying(255),
    state_ character varying(255),
    name_ character varying(255),
    parent_task_id_ character varying(64),
    description_ character varying(4000),
    task_def_key_ character varying(255),
    owner_ character varying(255),
    assignee_ character varying(255),
    delegation_ character varying(64),
    priority_ integer,
    create_time_ timestamp without time zone,
    in_progress_time_ timestamp without time zone,
    in_progress_started_by_ character varying(255),
    claim_time_ timestamp without time zone,
    claimed_by_ character varying(255),
    suspended_time_ timestamp without time zone,
    suspended_by_ character varying(255),
    in_progress_due_date_ timestamp without time zone,
    due_date_ timestamp without time zone,
    category_ character varying(255),
    suspension_state_ integer,
    tenant_id_ character varying(255) DEFAULT ''::character varying,
    form_key_ character varying(255),
    is_count_enabled_ boolean,
    var_count_ integer,
    id_link_count_ integer,
    sub_task_count_ integer
);


--
-- Name: act_ru_timer_job; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ru_timer_job (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    category_ character varying(255),
    type_ character varying(255) NOT NULL,
    lock_exp_time_ timestamp without time zone,
    lock_owner_ character varying(255),
    exclusive_ boolean,
    execution_id_ character varying(64),
    process_instance_id_ character varying(64),
    proc_def_id_ character varying(64),
    element_id_ character varying(255),
    element_name_ character varying(255),
    scope_id_ character varying(255),
    sub_scope_id_ character varying(255),
    scope_type_ character varying(255),
    scope_definition_id_ character varying(255),
    correlation_id_ character varying(255),
    retries_ integer,
    exception_stack_id_ character varying(64),
    exception_msg_ character varying(4000),
    duedate_ timestamp without time zone,
    repeat_ character varying(255),
    handler_type_ character varying(255),
    handler_cfg_ character varying(4000),
    custom_values_id_ character varying(64),
    create_time_ timestamp without time zone,
    tenant_id_ character varying(255) DEFAULT ''::character varying
);


--
-- Name: act_ru_variable; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.act_ru_variable (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    type_ character varying(255) NOT NULL,
    name_ character varying(255) NOT NULL,
    execution_id_ character varying(64),
    proc_inst_id_ character varying(64),
    task_id_ character varying(64),
    scope_id_ character varying(255),
    sub_scope_id_ character varying(255),
    scope_type_ character varying(255),
    bytearray_id_ character varying(64),
    double_ double precision,
    long_ bigint,
    text_ character varying(4000),
    text2_ character varying(4000),
    meta_info_ character varying(4000)
);


--
-- Name: ai_api_key; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_api_key (
    id bigint NOT NULL,
    name text,
    api_key text,
    platform text,
    url text,
    status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: ai_api_key_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_api_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_chat_conversation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_chat_conversation (
    id bigint NOT NULL,
    user_id bigint,
    title text,
    pinned boolean,
    pinned_time timestamp without time zone,
    role_id bigint,
    model_id bigint,
    model text,
    system_message text,
    temperature double precision,
    max_tokens integer,
    max_contexts integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: ai_chat_conversation_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_chat_conversation_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_chat_message; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_chat_message (
    id bigint NOT NULL,
    conversation_id bigint,
    reply_id bigint,
    type text,
    user_id bigint,
    role_id bigint,
    model text,
    model_id bigint,
    content text,
    reasoning_content text,
    use_context boolean,
    segment_ids text,
    web_search_pages text,
    attachment_urls text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: ai_chat_message_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_chat_message_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_chat_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_chat_role (
    id bigint NOT NULL,
    name text,
    avatar text,
    category text,
    description text,
    system_message text,
    user_id bigint,
    model_id bigint,
    knowledge_ids text,
    tool_ids text,
    mcp_client_names text,
    public_status boolean,
    sort integer,
    status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: ai_chat_role_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_chat_role_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_image; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_image (
    id bigint NOT NULL,
    user_id bigint,
    prompt text,
    platform text,
    model_id bigint,
    model text,
    width integer,
    height integer,
    status integer,
    finish_time timestamp without time zone,
    error_message text,
    pic_url text,
    public_status boolean,
    options text,
    buttons text,
    task_id text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: ai_image_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_image_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_knowledge; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_knowledge (
    id bigint NOT NULL,
    name text,
    description text,
    embedding_model_id bigint,
    embedding_model text,
    top_k integer,
    similarity_threshold double precision,
    status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: ai_knowledge_document; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_knowledge_document (
    id bigint NOT NULL,
    knowledge_id bigint,
    name text,
    url text,
    content text,
    content_length integer,
    tokens integer,
    segment_max_tokens integer,
    retrieval_count integer,
    status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: ai_knowledge_document_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_knowledge_document_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_knowledge_segment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_knowledge_segment (
    id bigint NOT NULL,
    knowledge_id bigint,
    document_id bigint,
    content text,
    content_length integer,
    vector_id text,
    tokens integer,
    retrieval_count integer,
    status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: ai_knowledge_segment_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_knowledge_segment_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_knowledge_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_knowledge_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_mind_map; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_mind_map (
    id bigint NOT NULL,
    user_id bigint,
    platform text,
    model_id bigint,
    model text,
    prompt text,
    generated_content text,
    error_message text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: ai_mind_map_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_mind_map_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_model; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_model (
    id bigint NOT NULL,
    key_id bigint,
    name text,
    model text,
    platform text,
    type integer,
    sort integer,
    status integer,
    temperature double precision,
    max_tokens integer,
    max_contexts integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: ai_model_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_model_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_music; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_music (
    id bigint NOT NULL,
    user_id bigint,
    title text,
    lyric text,
    image_url text,
    audio_url text,
    video_url text,
    status integer,
    generate_mode integer,
    description text,
    platform text,
    model text,
    tags text,
    duration double precision,
    public_status boolean,
    task_id text,
    error_message text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: ai_music_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_music_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_tool; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_tool (
    id bigint NOT NULL,
    name text,
    description text,
    status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: ai_tool_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_tool_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_workflow; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_workflow (
    id bigint NOT NULL,
    name text,
    code text,
    graph text,
    remark text,
    status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: ai_write; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_write (
    id bigint NOT NULL,
    user_id bigint,
    type integer,
    platform text,
    model_id bigint,
    model text,
    prompt text,
    generated_content text,
    original_content text,
    length integer,
    format integer,
    tone integer,
    language integer,
    error_message text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: ai_write_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_write_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bill_ext; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bill_ext (
    id bigint NOT NULL,
    bill_type character varying(64) NOT NULL,
    bill_id bigint NOT NULL,
    field_key character varying(64) NOT NULL,
    field_value text,
    field_type character varying(16) DEFAULT 'string'::character varying,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: bill_ext_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bill_ext_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bill_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bill_log (
    id bigint NOT NULL,
    bill_type character varying(64) NOT NULL,
    bill_id bigint NOT NULL,
    bill_no character varying(64) DEFAULT ''::character varying,
    operate_type character varying(32) NOT NULL,
    before_status smallint,
    after_status smallint,
    operator_id bigint,
    operator_name character varying(64) DEFAULT ''::character varying,
    operate_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    remark character varying(500) DEFAULT ''::character varying,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: bill_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bill_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bill_no_seq; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bill_no_seq (
    id bigint NOT NULL,
    bill_type character varying(64) NOT NULL,
    org_id bigint DEFAULT 0 NOT NULL,
    period character varying(16) NOT NULL,
    last_no bigint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: bill_no_seq_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bill_no_seq_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bill_relation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bill_relation (
    id bigint NOT NULL,
    source_type character varying(64) NOT NULL,
    source_id bigint NOT NULL,
    source_no character varying(64) DEFAULT ''::character varying,
    source_item_id bigint,
    target_type character varying(64) NOT NULL,
    target_id bigint NOT NULL,
    target_no character varying(64) DEFAULT ''::character varying,
    target_item_id bigint,
    qty numeric(24,6),
    status smallint DEFAULT 0,
    remark character varying(255) DEFAULT ''::character varying,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: COLUMN bill_relation.qty; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.bill_relation.qty IS '下推数量（行级关联时必填，用于防超推）';


--
-- Name: bill_relation_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bill_relation_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bill_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bill_type (
    id bigint NOT NULL,
    code character varying(64) NOT NULL,
    name character varying(64) NOT NULL,
    module character varying(32) DEFAULT ''::character varying,
    no_prefix character varying(16) DEFAULT ''::character varying,
    no_date_format character varying(16) DEFAULT 'yyyyMMdd'::character varying,
    no_reset character varying(8) DEFAULT 'D'::character varying,
    no_seq_length smallint DEFAULT 4,
    need_audit boolean DEFAULT false,
    bpm_process_key character varying(64) DEFAULT ''::character varying,
    affect_stock boolean DEFAULT false,
    affect_finance boolean DEFAULT false,
    status smallint DEFAULT 0,
    sort integer DEFAULT 0,
    remark character varying(255) DEFAULT ''::character varying,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: COLUMN bill_type.no_reset; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.bill_type.no_reset IS '重置周期：D 按日 / M 按月 / Y 按年 / N 不重置';


--
-- Name: COLUMN bill_type.no_seq_length; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.bill_type.no_seq_length IS '流水号位数，左补零';


--
-- Name: COLUMN bill_type.affect_finance; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.bill_type.affect_finance IS '是否产生会计事件（后期凭证引擎据此过滤）';


--
-- Name: bill_type_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bill_type_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bpm_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bpm_category (
    id bigint NOT NULL,
    name text,
    code text,
    description text,
    status integer,
    sort integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: bpm_category_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bpm_category_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bpm_form; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bpm_form (
    id bigint NOT NULL,
    name text,
    status integer,
    conf text,
    fields text,
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: bpm_form_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bpm_form_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bpm_oa_leave; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bpm_oa_leave (
    id bigint NOT NULL,
    user_id bigint,
    type integer,
    reason text,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    day bigint,
    status integer,
    process_instance_id text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: bpm_oa_leave_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bpm_oa_leave_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bpm_process_definition_info; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bpm_process_definition_info (
    id bigint NOT NULL,
    process_definition_id text,
    model_id text,
    model_type integer,
    category text,
    icon text,
    description text,
    form_type integer,
    form_id bigint,
    form_conf text,
    form_fields text,
    form_custom_create_path text,
    form_custom_view_path text,
    simple_model text,
    visible boolean,
    sort bigint,
    start_user_ids text,
    start_dept_ids text,
    manager_user_ids text,
    allow_cancel_running_process boolean,
    allow_withdraw_task boolean,
    process_id_rule text,
    auto_approval_type integer,
    title_setting text,
    summary_setting text,
    process_before_trigger_setting text,
    process_after_trigger_setting text,
    task_before_trigger_setting text,
    task_after_trigger_setting text,
    print_template_setting text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: bpm_process_definition_info_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bpm_process_definition_info_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bpm_process_expression; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bpm_process_expression (
    id bigint NOT NULL,
    name text,
    status integer,
    expression text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: bpm_process_expression_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bpm_process_expression_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bpm_process_instance_copy; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bpm_process_instance_copy (
    id bigint NOT NULL,
    start_user_id bigint,
    process_instance_name text,
    process_instance_id text,
    process_definition_id text,
    category text,
    activity_id text,
    activity_name text,
    task_id text,
    user_id bigint,
    reason text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: bpm_process_instance_copy_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bpm_process_instance_copy_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bpm_process_listener; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bpm_process_listener (
    id bigint NOT NULL,
    name text,
    status integer,
    type text,
    event text,
    value_type text,
    value text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: bpm_process_listener_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bpm_process_listener_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bpm_user_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bpm_user_group (
    id bigint NOT NULL,
    name text,
    description text,
    status integer,
    user_ids text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: bpm_user_group_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bpm_user_group_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_business_product_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_business_product_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_business_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_business_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_business_status_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_business_status_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_business_status_type_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_business_status_type_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_clue_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_clue_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_contact_business_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_contact_business_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_contact_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_contact_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_contract_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_contract_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_contract_product_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_contract_product_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_contract_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_contract_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_customer_limit_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_customer_limit_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_customer_pool_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_customer_pool_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_customer_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_customer_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_follow_up_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_follow_up_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_owner_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_owner_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_performance_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_performance_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_permission_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_permission_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_product_category_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_product_category_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_product_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_product_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_receivable_plan_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_receivable_plan_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_receivable_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_receivable_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dual; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dual (
    id smallint NOT NULL
);


--
-- Name: TABLE dual; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.dual IS '数据库连接的表';


--
-- Name: erp_account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_account (
    id bigint NOT NULL,
    name text,
    no text,
    remark text,
    status integer,
    sort integer,
    default_status boolean,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_account_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_account_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_customer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_customer (
    id bigint NOT NULL,
    name text,
    contact text,
    mobile text,
    telephone text,
    email text,
    fax text,
    remark text,
    status integer,
    sort integer,
    tax_no text,
    tax_percent numeric(24,6),
    bank_name text,
    bank_account text,
    bank_address text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    dept_id bigint,
    store_type character varying(20),
    settlement_mode character varying(20),
    credit_days integer,
    credit_limit numeric(24,6),
    code character varying(32)
);


--
-- Name: COLUMN erp_customer.dept_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_customer.dept_id IS '所属部门（门店节点，system_dept.id）';


--
-- Name: COLUMN erp_customer.store_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_customer.store_type IS '店型：DIRECT 直营 / FRANCHISE 加盟（字典 erp_store_type）';


--
-- Name: COLUMN erp_customer.settlement_mode; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_customer.settlement_mode IS '结算模式：PREPAID 先款后货 / MONTHLY 月结（字典 trade_settlement_mode）';


--
-- Name: COLUMN erp_customer.credit_days; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_customer.credit_days IS '账期天数（月结时生效）';


--
-- Name: COLUMN erp_customer.credit_limit; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_customer.credit_limit IS '信用额度（月结时生效）';


--
-- Name: COLUMN erp_customer.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_customer.code IS '客户编码（规则 KH + 6 位流水；租户内唯一）';


--
-- Name: erp_customer_account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_customer_account (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    dept_id bigint,
    biz_type smallint NOT NULL,
    amount numeric(24,2) NOT NULL,
    balance numeric(24,2) DEFAULT 0 NOT NULL,
    bill_time timestamp without time zone DEFAULT now() NOT NULL,
    source_type character varying(32),
    source_id bigint,
    source_no character varying(64),
    remark character varying(500),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT now() NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT now() NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE erp_customer_account; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.erp_customer_account IS '门店往来台账：正数=门店欠总部（应收增加），负数=门店已付/应收减少；余额=累计和';


--
-- Name: COLUMN erp_customer_account.biz_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_customer_account.biz_type IS '业务类型：1 配送应收 / 2 直拨应收 / 3 收款（含预收） / 4 收货差异调整 / 5 退货冲减 / 11 配送应收冲销 / 12 直拨应收冲销';


--
-- Name: COLUMN erp_customer_account.balance; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_customer_account.balance IS '记账后余额快照（同一门店串行记账，事务内取号后用 pg_advisory_xact_lock 保证）';


--
-- Name: erp_customer_account_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_customer_account_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_customer_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_customer_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_finance_payment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_finance_payment (
    id bigint NOT NULL,
    no text,
    status integer,
    payment_time timestamp without time zone,
    finance_user_id bigint,
    supplier_id bigint,
    account_id bigint,
    total_price numeric(24,6),
    discount_price numeric(24,6),
    payment_price numeric(24,6),
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_finance_payment_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_finance_payment_item (
    id bigint NOT NULL,
    payment_id bigint,
    biz_type integer,
    biz_id bigint,
    biz_no text,
    total_price numeric(24,6),
    paid_price numeric(24,6),
    payment_price numeric(24,6),
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_finance_payment_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_finance_payment_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_finance_payment_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_finance_payment_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_finance_receipt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_finance_receipt (
    id bigint NOT NULL,
    no text,
    status integer,
    receipt_time timestamp without time zone,
    finance_user_id bigint,
    customer_id bigint,
    account_id bigint,
    total_price numeric(24,6),
    discount_price numeric(24,6),
    receipt_price numeric(24,6),
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_finance_receipt_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_finance_receipt_item (
    id bigint NOT NULL,
    receipt_id bigint,
    biz_type integer,
    biz_id bigint,
    biz_no text,
    total_price numeric(24,6),
    receipted_price numeric(24,6),
    receipt_price numeric(24,6),
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_finance_receipt_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_finance_receipt_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_finance_receipt_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_finance_receipt_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_price_list; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_price_list (
    id bigint NOT NULL,
    code character varying(32),
    name character varying(64) NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    effective_date date,
    expiry_date date,
    remark character varying(255),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT now() NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT now() NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    price_includes_tax boolean DEFAULT false NOT NULL,
    pricer_user_id bigint,
    price_type character varying(16) NOT NULL
);


--
-- Name: TABLE erp_price_list; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.erp_price_list IS '价目表（头）：按 price_type 区分采购 / 配送等；适用对象见 erp_price_list_scope';


--
-- Name: COLUMN erp_price_list.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list.code IS '业务编码（编码规则 erp_purchase_price，前缀 CJJM）';


--
-- Name: COLUMN erp_price_list.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list.status IS '状态：0 启用 / 1 停用（仅启用中的价目表参与取价）';


--
-- Name: COLUMN erp_price_list.effective_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list.effective_date IS '生效日期（为空表示不限）';


--
-- Name: COLUMN erp_price_list.expiry_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list.expiry_date IS '失效日期（为空表示长期有效）';


--
-- Name: COLUMN erp_price_list.price_includes_tax; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list.price_includes_tax IS '报价口径：true 表示供应商报的是含税价（仅影响录入方向）。行上的 price 恒为不含税';


--
-- Name: COLUMN erp_price_list.pricer_user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list.pricer_user_id IS '定价员（system_users.id）；与 creator 区分，责任人不等于录入人';


--
-- Name: COLUMN erp_price_list.price_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list.price_type IS '价目表类型：PURCHASE 采购 / DELIVERY 配送；决定适用范围里的对象是供应商还是门店';


--
-- Name: erp_price_list_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_price_list_item (
    id bigint NOT NULL,
    price_id bigint NOT NULL,
    product_id bigint NOT NULL,
    price numeric(24,6) DEFAULT 0 NOT NULL,
    tax_percent numeric(24,6),
    remark character varying(255),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT now() NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT now() NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE erp_price_list_item; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.erp_price_list_item IS '价目表明细（行）：物料 + 单价(不含税) + 税率；同一价目表里同一物料只能有一行';


--
-- Name: COLUMN erp_price_list_item.product_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list_item.product_id IS '物料编号';


--
-- Name: COLUMN erp_price_list_item.price; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list_item.price IS '单价（**不含税**，权威值）；含税单价 = price × (1 + tax_percent/100)，是计算值不落库';


--
-- Name: COLUMN erp_price_list_item.tax_percent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list_item.tax_percent IS '税率(%)，如 13';


--
-- Name: erp_price_list_item_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_price_list_item_log (
    id bigint NOT NULL,
    price_id bigint NOT NULL,
    item_id bigint,
    product_id bigint NOT NULL,
    change_type character varying(16) NOT NULL,
    before_price numeric(24,6),
    after_price numeric(24,6),
    before_tax_percent numeric(24,6),
    after_tax_percent numeric(24,6),
    price_code character varying(32),
    price_name character varying(64),
    remark character varying(255),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT now() NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT now() NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE erp_price_list_item_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.erp_price_list_item_log IS '价目表价格变更留痕：供核算追溯「某物料在某价目表下的价格变动历史」';


--
-- Name: COLUMN erp_price_list_item_log.change_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list_item_log.change_type IS 'CREATE 新增行 / UPDATE 价格或税率变化 / DELETE 删行';


--
-- Name: COLUMN erp_price_list_item_log.price_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list_item_log.price_code IS '冗余价目表编码与名称：价目表改名/删除后，历史仍可读';


--
-- Name: COLUMN erp_price_list_item_log.price_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list_item_log.price_name IS '冗余价目表名称，理由同上';


--
-- Name: erp_price_list_item_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_price_list_item_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_price_list_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_price_list_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_price_list_scope; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_price_list_scope (
    id bigint NOT NULL,
    price_id bigint NOT NULL,
    partner_id bigint,
    is_default boolean DEFAULT false NOT NULL,
    remark character varying(255),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT now() NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT now() NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE erp_price_list_scope; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.erp_price_list_scope IS '价目表适用范围：一张价目表可适用 N 个对象（配送=门店）；partner_id 为空=通用范围';


--
-- Name: COLUMN erp_price_list_scope.partner_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list_scope.partner_id IS '适用对象编号：PURCHASE=供应商 erp_supplier.id；DELIVERY=门店 erp_customer.id；**为空=通用范围**（不限对象，优先级最低）';


--
-- Name: COLUMN erp_price_list_scope.is_default; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_price_list_scope.is_default IS '该对象下的默认价目表（取价时优先）；放在范围行上是为了支持「同一张表只对部分门店默认」';


--
-- Name: erp_price_list_scope_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_price_list_scope_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_price_list_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_price_list_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_product; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_product (
    id bigint NOT NULL,
    name text,
    bar_code text,
    category_id bigint,
    unit_id bigint,
    status integer,
    standard text,
    remark text,
    expiry_day integer,
    weight numeric(24,6),
    purchase_price numeric(24,6),
    sale_price numeric(24,6),
    min_price numeric(24,6),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    allow_central boolean DEFAULT true NOT NULL,
    allow_direct boolean DEFAULT true NOT NULL,
    code character varying(32)
);


--
-- Name: COLUMN erp_product.allow_central; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_product.allow_central IS '允许统配：中心库配送出库（工作台可选统配）';


--
-- Name: COLUMN erp_product.allow_direct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_product.allow_direct IS '允许直拨：中心库下采购订单、供应商直送门店（工作台可选直拨）';


--
-- Name: COLUMN erp_product.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_product.code IS '物料编码（编码规则 WL + 6 位流水；租户内唯一。见 sql/local/56_code_rule.sql）';


--
-- Name: erp_product_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_product_category (
    id bigint NOT NULL,
    parent_id bigint,
    name text,
    code text,
    sort integer,
    status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_product_category_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_product_category_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_product_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_product_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_product_unit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_product_unit (
    id bigint NOT NULL,
    name text,
    status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    code character varying(32)
);


--
-- Name: COLUMN erp_product_unit.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_product_unit.code IS '计量单位编码（规则 DW + 4 位流水；租户内唯一）';


--
-- Name: erp_product_unit_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_product_unit_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_purchase_in; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_purchase_in (
    id bigint NOT NULL,
    no text,
    status integer,
    supplier_id bigint,
    account_id bigint,
    in_time timestamp without time zone,
    order_id bigint,
    order_no text,
    total_count numeric(24,6),
    total_price numeric(24,6),
    payment_price numeric(24,6) DEFAULT 0,
    total_product_price numeric(24,6),
    total_tax_price numeric(24,6),
    discount_percent numeric(24,6),
    discount_price numeric(24,6),
    other_price numeric(24,6),
    file_url text,
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_purchase_in_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_purchase_in_items (
    id bigint NOT NULL,
    in_id bigint,
    order_item_id bigint,
    warehouse_id bigint,
    product_id bigint,
    product_unit_id bigint,
    product_price numeric(24,6),
    count numeric(24,6),
    total_price numeric(24,6),
    tax_percent numeric(24,6),
    tax_price numeric(24,6),
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    batch_no character varying(64),
    production_date date,
    expiry_date date
);


--
-- Name: COLUMN erp_purchase_in_items.batch_no; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_purchase_in_items.batch_no IS '批次号：为空时审核入库按 IN{yyyyMMdd}-{项id} 自动生成（ErpStockBatchService#receiveBatch）';


--
-- Name: COLUMN erp_purchase_in_items.production_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_purchase_in_items.production_date IS '生产日期（可空）';


--
-- Name: COLUMN erp_purchase_in_items.expiry_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_purchase_in_items.expiry_date IS '到期日期（可空）：效期预警口径，FIFO 的次级排序键';


--
-- Name: erp_purchase_in_items_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_purchase_in_items_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_purchase_in_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_purchase_in_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_purchase_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_purchase_order (
    id bigint NOT NULL,
    no text,
    status integer,
    supplier_id bigint,
    account_id bigint,
    order_time timestamp without time zone,
    total_count numeric(24,6),
    total_price numeric(24,6),
    total_product_price numeric(24,6),
    total_tax_price numeric(24,6),
    discount_percent numeric(24,6),
    discount_price numeric(24,6),
    deposit_price numeric(24,6),
    file_url text,
    remark text,
    in_count numeric(24,6) DEFAULT 0,
    return_count numeric(24,6) DEFAULT 0,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    settlement_type character varying(32),
    delivery_days integer
);


--
-- Name: COLUMN erp_purchase_order.settlement_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_purchase_order.settlement_type IS '结账方式（下单时从供应商带出，允许按单覆盖；字典 erp_supplier_settlement_type）';


--
-- Name: COLUMN erp_purchase_order.delivery_days; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_purchase_order.delivery_days IS '交期时间（天）（下单时从供应商带出，允许按单覆盖）';


--
-- Name: erp_purchase_order_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_purchase_order_items (
    id bigint NOT NULL,
    order_id bigint,
    product_id bigint,
    product_unit_id bigint,
    product_price numeric(24,6),
    count numeric(24,6),
    total_price numeric(24,6),
    tax_percent numeric(24,6),
    tax_price numeric(24,6),
    remark text,
    in_count numeric(24,6) DEFAULT 0,
    return_count numeric(24,6) DEFAULT 0,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_purchase_order_items_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_purchase_order_items_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_purchase_order_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_purchase_order_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_purchase_return; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_purchase_return (
    id bigint NOT NULL,
    no text,
    status integer,
    supplier_id bigint,
    account_id bigint,
    return_time timestamp without time zone,
    order_id bigint,
    order_no text,
    total_count numeric(24,6),
    total_price numeric(24,6),
    refund_price numeric(24,6) DEFAULT 0,
    total_product_price numeric(24,6),
    total_tax_price numeric(24,6),
    discount_percent numeric(24,6),
    discount_price numeric(24,6),
    other_price numeric(24,6),
    file_url text,
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_purchase_return_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_purchase_return_items (
    id bigint NOT NULL,
    return_id bigint,
    order_item_id bigint,
    warehouse_id bigint,
    product_id bigint,
    product_unit_id bigint,
    product_price numeric(24,6),
    count numeric(24,6),
    total_price numeric(24,6),
    tax_percent numeric(24,6),
    tax_price numeric(24,6),
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_purchase_return_items_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_purchase_return_items_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_purchase_return_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_purchase_return_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_sale_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_sale_order (
    id bigint NOT NULL,
    no text,
    status integer,
    customer_id bigint,
    account_id bigint,
    sale_user_id bigint,
    order_time timestamp without time zone,
    total_count numeric(24,6),
    total_price numeric(24,6),
    total_product_price numeric(24,6),
    total_tax_price numeric(24,6),
    discount_percent numeric(24,6),
    discount_price numeric(24,6),
    deposit_price numeric(24,6),
    file_url text,
    remark text,
    out_count numeric(24,6) DEFAULT 0,
    return_count numeric(24,6) DEFAULT 0,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_sale_order_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_sale_order_items (
    id bigint NOT NULL,
    order_id bigint,
    product_id bigint,
    product_unit_id bigint,
    product_price numeric(24,6),
    count numeric(24,6),
    total_price numeric(24,6),
    tax_percent numeric(24,6),
    tax_price numeric(24,6),
    remark text,
    out_count numeric(24,6) DEFAULT 0,
    return_count numeric(24,6) DEFAULT 0,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_sale_order_items_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_sale_order_items_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_sale_order_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_sale_order_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_sale_out; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_sale_out (
    id bigint NOT NULL,
    no text,
    status integer,
    customer_id bigint,
    account_id bigint,
    sale_user_id bigint,
    out_time timestamp without time zone,
    order_id bigint,
    order_no text,
    total_count numeric(24,6),
    total_price numeric(24,6),
    receipt_price numeric(24,6) DEFAULT 0,
    total_product_price numeric(24,6),
    total_tax_price numeric(24,6),
    discount_percent numeric(24,6),
    discount_price numeric(24,6),
    other_price numeric(24,6),
    file_url text,
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_sale_out_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_sale_out_items (
    id bigint NOT NULL,
    out_id bigint,
    order_item_id bigint,
    warehouse_id bigint,
    product_id bigint,
    product_unit_id bigint,
    product_price numeric(24,6),
    count numeric(24,6),
    total_price numeric(24,6),
    tax_percent numeric(24,6),
    tax_price numeric(24,6),
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    source_item_id bigint
);


--
-- Name: COLUMN erp_sale_out_items.source_item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_sale_out_items.source_item_id IS '来源业务行 id（门店要货单行 trade_order_item.id；手工出库单为空）';


--
-- Name: erp_sale_out_items_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_sale_out_items_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_sale_out_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_sale_out_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_sale_return; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_sale_return (
    id bigint NOT NULL,
    no text,
    status integer,
    customer_id bigint,
    account_id bigint,
    sale_user_id bigint,
    return_time timestamp without time zone,
    order_id bigint,
    order_no text,
    total_count numeric(24,6),
    total_price numeric(24,6),
    refund_price numeric(24,6) DEFAULT 0,
    total_product_price numeric(24,6),
    total_tax_price numeric(24,6),
    discount_percent numeric(24,6),
    discount_price numeric(24,6),
    other_price numeric(24,6),
    file_url text,
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_sale_return_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_sale_return_items (
    id bigint NOT NULL,
    return_id bigint,
    order_item_id bigint,
    warehouse_id bigint,
    product_id bigint,
    product_unit_id bigint,
    product_price numeric(24,6),
    count numeric(24,6),
    total_price numeric(24,6),
    tax_percent numeric(24,6),
    tax_price numeric(24,6),
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_sale_return_items_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_sale_return_items_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_sale_return_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_sale_return_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_stock; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_stock (
    id bigint NOT NULL,
    product_id bigint,
    warehouse_id bigint,
    count numeric(24,6),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_stock_batch; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_stock_batch (
    id bigint NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    warehouse_id bigint NOT NULL,
    product_id bigint NOT NULL,
    sku_id bigint DEFAULT 0 NOT NULL,
    batch_no character varying(64) NOT NULL,
    production_date date,
    expiry_date date,
    in_date date NOT NULL,
    count numeric(24,6) DEFAULT 0 NOT NULL,
    transit_count numeric(24,6) DEFAULT 0 NOT NULL,
    occupied_count numeric(24,6) DEFAULT 0 NOT NULL,
    inspecting_count numeric(24,6) DEFAULT 0 NOT NULL,
    unit_cost numeric(24,6) DEFAULT 0 NOT NULL,
    total_cost numeric(24,6) DEFAULT 0 NOT NULL,
    source_biz_type integer,
    source_biz_id bigint,
    source_biz_item_id bigint,
    source_biz_no character varying(64),
    source_reversed smallint DEFAULT 0 NOT NULL,
    remark character varying(255),
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE erp_stock_batch; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.erp_stock_batch IS 'ERP 批次库存：维度 = 仓库 × 物料 × 批次（sku_id 预留，0 = 按物料记账）；状态数量分列';


--
-- Name: COLUMN erp_stock_batch.warehouse_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.warehouse_id IS '仓库编号，关联 erp_warehouse.id';


--
-- Name: COLUMN erp_stock_batch.product_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.product_id IS '物料编号，关联 erp_product.id（SKU 统一是后续工作）';


--
-- Name: COLUMN erp_stock_batch.sku_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.sku_id IS 'SKU 编号预留位：0 = 未细分 SKU（本切片一律 0）';


--
-- Name: COLUMN erp_stock_batch.batch_no; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.batch_no IS '批次号：来源单据录入；未录入时由服务生成 IN{yyyyMMdd}-{入库单项id}';


--
-- Name: COLUMN erp_stock_batch.production_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.production_date IS '生产日期（可空）';


--
-- Name: COLUMN erp_stock_batch.expiry_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.expiry_date IS '到期日期（可空）：效期预警口径，FIFO 的次级排序键';


--
-- Name: COLUMN erp_stock_batch.in_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.in_date IS '入库日期：FIFO 主排序键（先入库先出）';


--
-- Name: COLUMN erp_stock_batch.count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.count IS '在仓数量（含被占用的部分，与 erp_stock.count 同一口径）';


--
-- Name: COLUMN erp_stock_batch.transit_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.transit_count IS '在途数量（可用量 = 在仓 − 占用 + 在途）';


--
-- Name: COLUMN erp_stock_batch.occupied_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.occupied_count IS '占用数量（已被单据锁定、尚未出库），是在仓数量的子集';


--
-- Name: COLUMN erp_stock_batch.inspecting_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.inspecting_count IS '待检数量（已到货、质检未放行），不计入可用量';


--
-- Name: COLUMN erp_stock_batch.unit_cost; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.unit_cost IS '批次单位成本（= 入库单价）';


--
-- Name: COLUMN erp_stock_batch.total_cost; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.total_cost IS '批次在仓成本 = count × unit_cost（出库按此结转）';


--
-- Name: COLUMN erp_stock_batch.source_biz_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.source_biz_type IS '来源业务类型，取值同 erp_stock_record.biz_type（ErpStockRecordBizTypeEnum）';


--
-- Name: COLUMN erp_stock_batch.source_biz_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.source_biz_id IS '来源单据编号，例如 erp_stock_in.id';


--
-- Name: COLUMN erp_stock_batch.source_biz_item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.source_biz_item_id IS '来源单据项编号，例如 erp_stock_in_item.id；与 source_biz_type 一起作为幂等键';


--
-- Name: COLUMN erp_stock_batch.source_biz_no; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.source_biz_no IS '来源单号，例如 QTRK20260928000001';


--
-- Name: COLUMN erp_stock_batch.source_reversed; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.source_reversed IS '来源是否已反审核冲销：0 否 / 1 是（反审核可逆，重新审核会复位）';


--
-- Name: COLUMN erp_stock_batch.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_batch.deleted IS '逻辑删除：0 未删除 / 1 已删除（smallint，与本库既有口径一致）';


--
-- Name: erp_stock_batch_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_stock_batch_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_stock_check; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_stock_check (
    id bigint NOT NULL,
    no text,
    check_time timestamp without time zone,
    total_count numeric(24,6),
    total_price numeric(24,6),
    status integer,
    remark text,
    file_url text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_stock_check_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_stock_check_item (
    id bigint NOT NULL,
    check_id bigint,
    warehouse_id bigint,
    product_id bigint,
    product_unit_id bigint,
    product_price numeric(24,6),
    stock_count numeric(24,6),
    actual_count numeric(24,6),
    count numeric(24,6),
    total_price numeric(24,6),
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_stock_check_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_stock_check_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_stock_check_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_stock_check_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_stock_in; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_stock_in (
    id bigint NOT NULL,
    no text,
    supplier_id bigint,
    in_time timestamp without time zone,
    total_count numeric(24,6),
    total_price numeric(24,6),
    status integer,
    remark text,
    file_url text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_stock_in_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_stock_in_item (
    id bigint NOT NULL,
    in_id bigint,
    warehouse_id bigint,
    product_id bigint,
    product_unit_id bigint,
    product_price numeric(24,6),
    count numeric(24,6),
    total_price numeric(24,6),
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    batch_no character varying(64),
    production_date date,
    expiry_date date
);


--
-- Name: COLUMN erp_stock_in_item.batch_no; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_in_item.batch_no IS '批次号：为空时审核入库按 IN{yyyyMMdd}-{项id} 自动生成';


--
-- Name: COLUMN erp_stock_in_item.production_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_in_item.production_date IS '生产日期（可空）';


--
-- Name: COLUMN erp_stock_in_item.expiry_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_in_item.expiry_date IS '到期日期（可空）：用于效期预警与 FIFO 次级排序';


--
-- Name: erp_stock_in_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_stock_in_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_stock_in_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_stock_in_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_stock_move; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_stock_move (
    id bigint NOT NULL,
    no text,
    move_time timestamp without time zone,
    total_count numeric(24,6),
    total_price numeric(24,6),
    status integer,
    remark text,
    file_url text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_stock_move_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_stock_move_item (
    id bigint NOT NULL,
    move_id bigint,
    from_warehouse_id bigint,
    to_warehouse_id bigint,
    product_id bigint,
    product_unit_id bigint,
    product_price numeric(24,6),
    count numeric(24,6),
    total_price numeric(24,6),
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_stock_move_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_stock_move_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_stock_move_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_stock_move_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_stock_out; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_stock_out (
    id bigint NOT NULL,
    no text,
    customer_id bigint,
    out_time timestamp without time zone,
    total_count numeric(24,6),
    total_price numeric(24,6),
    status integer,
    remark text,
    file_url text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_stock_out_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_stock_out_item (
    id bigint NOT NULL,
    out_id bigint,
    warehouse_id bigint,
    product_id bigint,
    product_unit_id bigint,
    product_price numeric(24,6),
    count numeric(24,6),
    total_price numeric(24,6),
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: erp_stock_out_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_stock_out_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_stock_out_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_stock_out_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_stock_record; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_stock_record (
    id bigint NOT NULL,
    product_id bigint,
    warehouse_id bigint,
    count numeric(24,6),
    total_count numeric(24,6),
    biz_type integer,
    biz_id bigint,
    biz_item_id bigint,
    biz_no text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    batch_no character varying(64),
    stock_state character varying(16),
    unit_cost numeric(24,6),
    total_cost numeric(24,6),
    sku_id bigint
);


--
-- Name: COLUMN erp_stock_record.batch_no; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_record.batch_no IS '批次号：出库按 FIFO 拆批后，一行流水对应一个批次';


--
-- Name: COLUMN erp_stock_record.stock_state; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_record.stock_state IS '状态：IN_STOCK 在仓 / IN_TRANSIT 在途 / OCCUPIED 占用 / INSPECTING 待检';


--
-- Name: COLUMN erp_stock_record.unit_cost; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_record.unit_cost IS '本行批次单位成本；为空表示老流水（未启用批次前）';


--
-- Name: COLUMN erp_stock_record.total_cost; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_record.total_cost IS '本行成本金额 = count × unit_cost（出库为负，即结转成本）';


--
-- Name: COLUMN erp_stock_record.sku_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_stock_record.sku_id IS 'SKU 编号预留位：NULL/0 = 按物料记账（本切片）';


--
-- Name: erp_stock_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_stock_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_stock_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_stock_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_supplier; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_supplier (
    id bigint NOT NULL,
    name text,
    contact text,
    mobile text,
    telephone text,
    email text,
    fax text,
    remark text,
    status integer,
    sort integer,
    tax_no text,
    tax_percent numeric(24,6),
    bank_name text,
    bank_account text,
    bank_address text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    code character varying(32),
    account_name character varying(128),
    registered_address character varying(255),
    settlement_type character varying(32),
    credit_days integer,
    invoice_mode character varying(32),
    invoice_ratio numeric(5,2),
    invoice_type character varying(32),
    delivery_days integer,
    contract_signed boolean DEFAULT false,
    contract_entity character varying(128),
    business_license_urls character varying(1024),
    production_license_urls character varying(1024)
);


--
-- Name: COLUMN erp_supplier.tax_percent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_supplier.tax_percent IS '开票税点(%)：0 表示免税，其余填 1~13（开票/应付单据据此带出，允许按单覆盖）';


--
-- Name: COLUMN erp_supplier.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_supplier.code IS '供应商编码（规则 GYS + 6 位流水；租户内唯一）';


--
-- Name: COLUMN erp_supplier.account_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_supplier.account_name IS '账户户名（银行账户的开户名称，通常同公司全称）';


--
-- Name: COLUMN erp_supplier.registered_address; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_supplier.registered_address IS '注册地址（营业执照上的营业地址；开增值税专用发票需要）';


--
-- Name: COLUMN erp_supplier.settlement_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_supplier.settlement_type IS '结账方式：MONTHLY 月结 / HALF_MONTH 半月结 / CASH_FIRST 次结(先款后货) / GOODS_FIRST 次结(先货后款)（字典 erp_supplier_settlement_type）';


--
-- Name: COLUMN erp_supplier.credit_days; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_supplier.credit_days IS '账期天数（月结/半月结时有意义，如月结 30 天、半月结 15 天）';


--
-- Name: COLUMN erp_supplier.invoice_mode; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_supplier.invoice_mode IS '开票情况：FULL 全额开票 / RATIO 按销售额比例开票 / PLUS_TAX 需加税点 / NONE 不开发票（字典 erp_supplier_invoice_mode）';


--
-- Name: COLUMN erp_supplier.invoice_ratio; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_supplier.invoice_ratio IS '开票比例(%)：开票情况为「按销售额比例开票」时填写，如 15~25';


--
-- Name: COLUMN erp_supplier.invoice_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_supplier.invoice_type IS '开票类型：VAT_NORMAL 增值税普通发票 / VAT_SPECIAL 增值税专用发票（字典 erp_supplier_invoice_type）';


--
-- Name: COLUMN erp_supplier.delivery_days; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_supplier.delivery_days IS '交期时间（天）：下单到到货的承诺天数';


--
-- Name: COLUMN erp_supplier.contract_signed; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_supplier.contract_signed IS '是否已签订合同';


--
-- Name: COLUMN erp_supplier.contract_entity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_supplier.contract_entity IS '合同签订主体（由亚特哪个公司/主体签订）';


--
-- Name: COLUMN erp_supplier.business_license_urls; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_supplier.business_license_urls IS '营业执照（文件/图片，多个用逗号分隔）';


--
-- Name: COLUMN erp_supplier.production_license_urls; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_supplier.production_license_urls IS '生产许可证（文件/图片，多个用逗号分隔）';


--
-- Name: erp_supplier_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_supplier_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erp_warehouse; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erp_warehouse (
    id bigint NOT NULL,
    name text,
    address text,
    sort bigint,
    remark text,
    principal text,
    warehouse_price numeric(24,6),
    truckage_price numeric(24,6),
    status integer,
    default_status boolean,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    warehouse_type character varying(16) DEFAULT 'CENTER'::character varying NOT NULL,
    store_customer_id bigint,
    dept_id bigint,
    code character varying(32)
);


--
-- Name: COLUMN erp_warehouse.warehouse_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_warehouse.warehouse_type IS '仓库类型：CENTER 中心库 / STORE 门店仓';


--
-- Name: COLUMN erp_warehouse.store_customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_warehouse.store_customer_id IS '门店仓对应的门店客户（erp_customer.id）；中心库为空';


--
-- Name: COLUMN erp_warehouse.dept_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_warehouse.dept_id IS '门店仓对应的部门（erp_customer.dept_id 冗余，便于按组织过滤）';


--
-- Name: COLUMN erp_warehouse.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.erp_warehouse.code IS '仓库编码（规则 CK + 4 位流水；租户内唯一）';


--
-- Name: erp_warehouse_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erp_warehouse_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flw_channel_definition; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flw_channel_definition (
    id_ character varying(255) NOT NULL,
    name_ character varying(255),
    version_ integer,
    key_ character varying(255),
    category_ character varying(255),
    type_ character varying(255),
    implementation_ character varying(255),
    deployment_id_ character varying(255),
    create_time_ timestamp(3) without time zone,
    tenant_id_ character varying(255),
    resource_name_ character varying(255),
    description_ character varying(255)
);


--
-- Name: flw_event_definition; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flw_event_definition (
    id_ character varying(255) NOT NULL,
    name_ character varying(255),
    version_ integer,
    key_ character varying(255),
    category_ character varying(255),
    deployment_id_ character varying(255),
    tenant_id_ character varying(255),
    resource_name_ character varying(255),
    description_ character varying(255)
);


--
-- Name: flw_event_deployment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flw_event_deployment (
    id_ character varying(255) NOT NULL,
    name_ character varying(255),
    category_ character varying(255),
    deploy_time_ timestamp(3) without time zone,
    tenant_id_ character varying(255),
    parent_deployment_id_ character varying(255)
);


--
-- Name: flw_event_resource; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flw_event_resource (
    id_ character varying(255) NOT NULL,
    name_ character varying(255),
    deployment_id_ character varying(255),
    resource_bytes_ bytea
);


--
-- Name: flw_ru_batch; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flw_ru_batch (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    type_ character varying(64) NOT NULL,
    search_key_ character varying(255),
    search_key2_ character varying(255),
    create_time_ timestamp without time zone NOT NULL,
    complete_time_ timestamp without time zone,
    status_ character varying(255),
    batch_doc_id_ character varying(64),
    tenant_id_ character varying(255) DEFAULT ''::character varying
);


--
-- Name: flw_ru_batch_part; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flw_ru_batch_part (
    id_ character varying(64) NOT NULL,
    rev_ integer,
    batch_id_ character varying(64),
    type_ character varying(64) NOT NULL,
    scope_id_ character varying(64),
    sub_scope_id_ character varying(64),
    scope_type_ character varying(64),
    search_key_ character varying(255),
    search_key2_ character varying(255),
    create_time_ timestamp without time zone NOT NULL,
    complete_time_ timestamp without time zone,
    status_ character varying(255),
    result_doc_id_ character varying(64),
    tenant_id_ character varying(255) DEFAULT ''::character varying
);


--
-- Name: fms_account_set; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_account_set (
    id bigint NOT NULL,
    company_code text,
    company_name text,
    company_profile text,
    industry text,
    location text,
    legal_representative text,
    legal_representative_id_number text,
    business_license_number text,
    organization_code text,
    remark text,
    contact_name text,
    office_telephone text,
    mobile text,
    fax_number text,
    qq_number text,
    email text,
    other_contact text,
    address text,
    currency_id bigint,
    start_time timestamp without time zone,
    standard integer,
    initialized boolean,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_account_set_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_account_set_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_account_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_account_user (
    id bigint NOT NULL,
    account_set_id bigint,
    user_id bigint,
    default_status boolean,
    founder boolean,
    level integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_account_user_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_account_user_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_assist_combination; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_assist_combination (
    id bigint NOT NULL,
    subject_id bigint,
    account_set_id bigint,
    items text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_assist_combination_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_assist_combination_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_auxiliary_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_auxiliary_item (
    id bigint NOT NULL,
    code text,
    name text,
    auxiliary_type_id bigint,
    status integer,
    account_set_id bigint,
    remark text,
    specification text,
    unit text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_auxiliary_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_auxiliary_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_auxiliary_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_auxiliary_type (
    id bigint NOT NULL,
    name text,
    system_preset boolean,
    account_set_id bigint,
    type integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_auxiliary_type_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_auxiliary_type_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_balance_sheet_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_balance_sheet_config (
    id bigint NOT NULL,
    name text,
    row_no integer,
    formula text,
    remark text,
    editable boolean,
    sort integer,
    account_set_id bigint,
    level integer,
    row_id integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_balance_sheet_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_balance_sheet_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_balance_sheet_report; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_balance_sheet_report (
    id bigint NOT NULL,
    from_period integer,
    to_period integer,
    type integer,
    level integer,
    name text,
    row_no integer,
    formula text,
    remark text,
    editable boolean,
    sort integer,
    opening_amount numeric(24,6),
    closing_amount numeric(24,6),
    account_set_id bigint,
    settled boolean,
    row_id integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_balance_sheet_report_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_balance_sheet_report_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_cash_flow_extend_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_cash_flow_extend_config (
    id bigint NOT NULL,
    name text,
    row_no integer,
    formula text,
    remark text,
    category integer,
    type integer,
    current_amount numeric(24,6),
    year_amount numeric(24,6),
    editable boolean,
    account_set_id bigint,
    sort integer,
    level integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_cash_flow_extend_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_cash_flow_extend_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_cash_flow_extend_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_cash_flow_extend_data (
    id bigint NOT NULL,
    name text,
    row_no integer,
    formula text,
    remark text,
    category integer,
    current_amount numeric(24,6),
    year_amount numeric(24,6),
    from_period integer,
    editable boolean,
    account_set_id bigint,
    sort integer,
    to_period integer,
    type integer,
    level integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_cash_flow_extend_data_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_cash_flow_extend_data_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_cash_flow_statement_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_cash_flow_statement_config (
    id bigint NOT NULL,
    name text,
    row_no integer,
    formula text,
    remark text,
    editable boolean,
    sort integer,
    category integer,
    account_set_id bigint,
    level integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_cash_flow_statement_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_cash_flow_statement_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_cash_flow_statement_report; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_cash_flow_statement_report (
    id bigint NOT NULL,
    from_period integer,
    name text,
    row_no integer,
    formula text,
    remark text,
    editable boolean,
    current_amount numeric(24,6),
    year_amount numeric(24,6),
    sort integer,
    category integer,
    account_set_id bigint,
    to_period integer,
    type integer,
    level integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_cash_flow_statement_report_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_cash_flow_statement_report_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_closing; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_closing (
    id bigint NOT NULL,
    name text,
    period_end boolean,
    subject_id bigint,
    formula_rule integer,
    time_type integer,
    voucher_word_id bigint,
    digest text,
    voucher_type integer,
    prior_year_adjustment_subject_id bigint,
    adjustment_closing_subject_id bigint,
    other_closing_subject_id bigint,
    reverse_balance boolean,
    type integer,
    account_set_id bigint,
    closing_day integer,
    subject_rules text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_closing_period; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_closing_period (
    id bigint NOT NULL,
    closing_time timestamp without time zone,
    account_set_id bigint,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_closing_period_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_closing_period_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_closing_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_closing_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_closing_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_closing_template (
    id bigint NOT NULL,
    account_set_id bigint,
    preset_code text,
    name text,
    category integer,
    period_end boolean,
    subject_id bigint,
    formula_rule integer,
    time_type integer,
    subject_rules text,
    sort integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_closing_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_closing_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_closing_voucher; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_closing_voucher (
    id bigint NOT NULL,
    closing_id bigint,
    voucher_id bigint,
    voucher_time timestamp without time zone,
    amount numeric(24,6),
    closed boolean,
    account_set_id bigint,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_closing_voucher_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_closing_voucher_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_currency; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_currency (
    id bigint NOT NULL,
    code text,
    name text,
    exchange_rate numeric(24,6),
    standard boolean,
    account_set_id bigint,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_currency_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_currency_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_digest; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_digest (
    id bigint NOT NULL,
    content text,
    account_set_id bigint,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_digest_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_digest_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_finance_indicator; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_finance_indicator (
    id bigint NOT NULL,
    account_set_id bigint,
    name text,
    code text,
    type integer,
    formula text,
    sort integer,
    status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_finance_indicator_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_finance_indicator_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_finance_parameter; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_finance_parameter (
    id bigint NOT NULL,
    account_set_id bigint,
    level integer,
    subject_code_rule text,
    ledger_balance_mode integer,
    deficit_check boolean,
    voucher_review_required boolean,
    asset_period_locked boolean,
    taxpayer_name text,
    taxpayer_number text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_finance_parameter_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_finance_parameter_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_income_statement_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_income_statement_config (
    id bigint NOT NULL,
    name text,
    row_no integer,
    formula text,
    sort integer,
    editable boolean,
    account_set_id bigint,
    level integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_income_statement_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_income_statement_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_income_statement_report; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_income_statement_report (
    id bigint NOT NULL,
    type integer,
    from_period integer,
    to_period integer,
    name text,
    row_no integer,
    formula text,
    sort integer,
    editable boolean,
    current_amount numeric(24,6),
    year_amount numeric(24,6),
    account_set_id bigint,
    level integer,
    settled boolean,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_income_statement_report_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_income_statement_report_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_initial_balance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_initial_balance (
    id bigint NOT NULL,
    subject_id bigint,
    auxiliary_accounting boolean,
    opening_amount numeric(24,6),
    opening_quantity numeric(24,6),
    year_debit_amount numeric(24,6),
    year_debit_quantity numeric(24,6),
    year_credit_amount numeric(24,6),
    year_credit_quantity numeric(24,6),
    year_opening_amount numeric(24,6),
    year_opening_quantity numeric(24,6),
    profit_loss_amount numeric(24,6),
    profit_loss_quantity numeric(24,6),
    account_set_id bigint,
    assist_balances text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_initial_balance_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_initial_balance_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_report_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_report_template (
    id bigint NOT NULL,
    name text,
    row_no integer,
    formula text,
    remark text,
    editable boolean,
    sort integer,
    row_id integer,
    type integer,
    category integer,
    level integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_report_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_report_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_subject; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_subject (
    id bigint NOT NULL,
    code text,
    name text,
    parent_id bigint,
    type integer,
    category integer,
    balance_direction integer,
    quantity_unit text,
    cash boolean,
    status integer,
    level integer,
    quantity_accounting boolean,
    account_set_id bigint,
    auxiliary_type_ids text,
    currency_ids text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_subject_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_subject_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_subject_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_subject_template (
    id bigint NOT NULL,
    code text,
    name text,
    parent_id bigint,
    type integer,
    category integer,
    balance_direction integer,
    quantity_unit text,
    cash boolean,
    status integer,
    level integer,
    quantity_accounting boolean,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_subject_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_subject_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_voucher; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_voucher (
    id bigint NOT NULL,
    voucher_word_id bigint,
    voucher_number integer,
    voucher_time timestamp without time zone,
    attachment_urls text,
    attachment_count integer,
    debit_amount numeric(24,6),
    credit_amount numeric(24,6),
    total numeric(24,6),
    status integer,
    reviewer_user_id bigint,
    account_set_id bigint,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_voucher_entry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_voucher_entry (
    id bigint NOT NULL,
    digest text,
    subject_name text,
    quantity numeric(24,6),
    debit_amount numeric(24,6),
    credit_amount numeric(24,6),
    voucher_id bigint,
    subject_code text,
    sort integer,
    subject_id bigint,
    account_set_id bigint,
    unit_price numeric(24,6),
    assist_combination_id bigint,
    auxiliaries text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_voucher_entry_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_voucher_entry_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_voucher_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_voucher_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_voucher_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_voucher_template (
    id bigint NOT NULL,
    name text,
    category_id bigint,
    entries text,
    account_set_id bigint,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_voucher_template_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_voucher_template_category (
    id bigint NOT NULL,
    name text,
    account_set_id bigint,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_voucher_template_category_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_voucher_template_category_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_voucher_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_voucher_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fms_voucher_word; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fms_voucher_word (
    id bigint NOT NULL,
    name text,
    print_title text,
    default_status boolean,
    sort integer,
    account_set_id bigint,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: fms_voucher_word_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fms_voucher_word_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_attendance_clock_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_attendance_clock_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_attendance_group_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_attendance_group_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_attendance_holiday_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_attendance_holiday_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_attendance_leave_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_attendance_leave_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_employee_certificate_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_employee_certificate_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_employee_change_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_employee_change_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_employee_contact_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_employee_contact_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_employee_contract_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_employee_contract_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_employee_education_experience_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_employee_education_experience_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_employee_file_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_employee_file_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_employee_personal_note_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_employee_personal_note_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_employee_quit_info_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_employee_quit_info_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_employee_salary_card_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_employee_salary_card_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_employee_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_employee_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_employee_training_experience_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_employee_training_experience_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_employee_work_experience_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_employee_work_experience_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_insurance_employee_info_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_insurance_employee_info_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_insurance_month_employee_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_insurance_month_employee_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_insurance_month_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_insurance_month_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_insurance_scheme_project_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_insurance_scheme_project_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_insurance_scheme_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_insurance_scheme_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_performance_assessment_action_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_performance_assessment_action_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_performance_assessment_appeal_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_performance_assessment_appeal_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_performance_assessment_dimension_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_performance_assessment_dimension_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_performance_assessment_quota_score_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_performance_assessment_quota_score_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_performance_assessment_quota_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_performance_assessment_quota_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_performance_assessment_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_performance_assessment_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_performance_assessment_stage_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_performance_assessment_stage_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_performance_assessment_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_performance_assessment_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_performance_plan_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_performance_plan_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_performance_result_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_performance_result_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_recruit_candidate_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_recruit_candidate_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_recruit_channel_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_recruit_channel_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_recruit_interview_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_recruit_interview_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_recruit_post_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_recruit_post_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_recruit_post_type_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_recruit_post_type_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_salary_change_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_salary_change_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_salary_change_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_salary_change_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_salary_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_salary_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_salary_employee_info_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_salary_employee_info_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_salary_group_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_salary_group_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_salary_month_employee_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_salary_month_employee_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_salary_month_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_salary_month_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_salary_option_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_salary_option_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_salary_option_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_salary_option_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_salary_slip_send_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_salary_slip_send_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_salary_slip_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_salary_slip_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_salary_slip_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_salary_slip_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hrm_salary_tax_rule_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hrm_salary_tax_rule_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_channel_material_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_channel_material_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_channel_message_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_channel_message_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_channel_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_channel_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_conversation_read_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_conversation_read_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_face_pack_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_face_pack_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_face_pack_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_face_pack_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_face_user_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_face_user_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_friend_request_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_friend_request_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_friend_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_friend_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_group_member_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_group_member_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_group_message_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_group_message_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_group_request_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_group_request_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_group_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_group_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_private_message_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_private_message_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_rtc_call_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_rtc_call_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_rtc_participant_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_rtc_participant_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: im_sensitive_word_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.im_sensitive_word_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: infra_api_access_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.infra_api_access_log (
    id bigint NOT NULL,
    trace_id character varying(64) DEFAULT ''::character varying NOT NULL,
    user_id bigint DEFAULT 0 NOT NULL,
    user_type smallint DEFAULT 0 NOT NULL,
    application_name character varying(50) NOT NULL,
    request_method character varying(16) DEFAULT ''::character varying NOT NULL,
    request_url character varying(255) DEFAULT ''::character varying NOT NULL,
    request_params text,
    response_body text,
    user_ip character varying(50) NOT NULL,
    user_agent character varying(512) NOT NULL,
    operate_module character varying(50) DEFAULT NULL::character varying,
    operate_name character varying(50) DEFAULT NULL::character varying,
    operate_type smallint DEFAULT 0,
    begin_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    duration integer NOT NULL,
    result_code integer DEFAULT 0 NOT NULL,
    result_msg character varying(512) DEFAULT ''::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE infra_api_access_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.infra_api_access_log IS 'API 访问日志表';


--
-- Name: COLUMN infra_api_access_log.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.id IS '日志主键';


--
-- Name: COLUMN infra_api_access_log.trace_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.trace_id IS '链路追踪编号';


--
-- Name: COLUMN infra_api_access_log.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.user_id IS '用户编号';


--
-- Name: COLUMN infra_api_access_log.user_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.user_type IS '用户类型';


--
-- Name: COLUMN infra_api_access_log.application_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.application_name IS '应用名';


--
-- Name: COLUMN infra_api_access_log.request_method; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.request_method IS '请求方法名';


--
-- Name: COLUMN infra_api_access_log.request_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.request_url IS '请求地址';


--
-- Name: COLUMN infra_api_access_log.request_params; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.request_params IS '请求参数';


--
-- Name: COLUMN infra_api_access_log.response_body; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.response_body IS '响应结果';


--
-- Name: COLUMN infra_api_access_log.user_ip; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.user_ip IS '用户 IP';


--
-- Name: COLUMN infra_api_access_log.user_agent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.user_agent IS '浏览器 UA';


--
-- Name: COLUMN infra_api_access_log.operate_module; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.operate_module IS '操作模块';


--
-- Name: COLUMN infra_api_access_log.operate_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.operate_name IS '操作名';


--
-- Name: COLUMN infra_api_access_log.operate_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.operate_type IS '操作分类';


--
-- Name: COLUMN infra_api_access_log.begin_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.begin_time IS '开始请求时间';


--
-- Name: COLUMN infra_api_access_log.end_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.end_time IS '结束请求时间';


--
-- Name: COLUMN infra_api_access_log.duration; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.duration IS '执行时长';


--
-- Name: COLUMN infra_api_access_log.result_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.result_code IS '结果码';


--
-- Name: COLUMN infra_api_access_log.result_msg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.result_msg IS '结果提示';


--
-- Name: COLUMN infra_api_access_log.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.creator IS '创建者';


--
-- Name: COLUMN infra_api_access_log.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.create_time IS '创建时间';


--
-- Name: COLUMN infra_api_access_log.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.updater IS '更新者';


--
-- Name: COLUMN infra_api_access_log.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.update_time IS '更新时间';


--
-- Name: COLUMN infra_api_access_log.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.deleted IS '是否删除';


--
-- Name: COLUMN infra_api_access_log.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_access_log.tenant_id IS '租户编号';


--
-- Name: infra_api_access_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.infra_api_access_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: infra_api_error_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.infra_api_error_log (
    id bigint NOT NULL,
    trace_id character varying(64) NOT NULL,
    user_id bigint DEFAULT 0 NOT NULL,
    user_type smallint DEFAULT 0 NOT NULL,
    application_name character varying(50) NOT NULL,
    request_method character varying(16) NOT NULL,
    request_url character varying(255) NOT NULL,
    request_params character varying(8000) NOT NULL,
    user_ip character varying(50) NOT NULL,
    user_agent character varying(512) NOT NULL,
    exception_time timestamp without time zone NOT NULL,
    exception_name character varying(128) DEFAULT ''::character varying NOT NULL,
    exception_message text NOT NULL,
    exception_root_cause_message text NOT NULL,
    exception_stack_trace text NOT NULL,
    exception_class_name character varying(512) NOT NULL,
    exception_file_name character varying(512) NOT NULL,
    exception_method_name character varying(512) NOT NULL,
    exception_line_number integer NOT NULL,
    process_status smallint NOT NULL,
    process_time timestamp without time zone,
    process_user_id integer DEFAULT 0,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE infra_api_error_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.infra_api_error_log IS '系统异常日志';


--
-- Name: COLUMN infra_api_error_log.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.id IS '编号';


--
-- Name: COLUMN infra_api_error_log.trace_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.trace_id IS '链路追踪编号';


--
-- Name: COLUMN infra_api_error_log.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.user_id IS '用户编号';


--
-- Name: COLUMN infra_api_error_log.user_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.user_type IS '用户类型';


--
-- Name: COLUMN infra_api_error_log.application_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.application_name IS '应用名';


--
-- Name: COLUMN infra_api_error_log.request_method; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.request_method IS '请求方法名';


--
-- Name: COLUMN infra_api_error_log.request_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.request_url IS '请求地址';


--
-- Name: COLUMN infra_api_error_log.request_params; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.request_params IS '请求参数';


--
-- Name: COLUMN infra_api_error_log.user_ip; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.user_ip IS '用户 IP';


--
-- Name: COLUMN infra_api_error_log.user_agent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.user_agent IS '浏览器 UA';


--
-- Name: COLUMN infra_api_error_log.exception_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.exception_time IS '异常发生时间';


--
-- Name: COLUMN infra_api_error_log.exception_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.exception_name IS '异常名';


--
-- Name: COLUMN infra_api_error_log.exception_message; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.exception_message IS '异常导致的消息';


--
-- Name: COLUMN infra_api_error_log.exception_root_cause_message; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.exception_root_cause_message IS '异常导致的根消息';


--
-- Name: COLUMN infra_api_error_log.exception_stack_trace; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.exception_stack_trace IS '异常的栈轨迹';


--
-- Name: COLUMN infra_api_error_log.exception_class_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.exception_class_name IS '异常发生的类全名';


--
-- Name: COLUMN infra_api_error_log.exception_file_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.exception_file_name IS '异常发生的类文件';


--
-- Name: COLUMN infra_api_error_log.exception_method_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.exception_method_name IS '异常发生的方法名';


--
-- Name: COLUMN infra_api_error_log.exception_line_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.exception_line_number IS '异常发生的方法所在行';


--
-- Name: COLUMN infra_api_error_log.process_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.process_status IS '处理状态';


--
-- Name: COLUMN infra_api_error_log.process_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.process_time IS '处理时间';


--
-- Name: COLUMN infra_api_error_log.process_user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.process_user_id IS '处理用户编号';


--
-- Name: COLUMN infra_api_error_log.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.creator IS '创建者';


--
-- Name: COLUMN infra_api_error_log.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.create_time IS '创建时间';


--
-- Name: COLUMN infra_api_error_log.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.updater IS '更新者';


--
-- Name: COLUMN infra_api_error_log.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.update_time IS '更新时间';


--
-- Name: COLUMN infra_api_error_log.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.deleted IS '是否删除';


--
-- Name: COLUMN infra_api_error_log.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_api_error_log.tenant_id IS '租户编号';


--
-- Name: infra_api_error_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.infra_api_error_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: infra_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.infra_config (
    id bigint NOT NULL,
    category character varying(50) NOT NULL,
    type smallint NOT NULL,
    name character varying(100) DEFAULT ''::character varying NOT NULL,
    config_key character varying(100) DEFAULT ''::character varying NOT NULL,
    value character varying(500) DEFAULT ''::character varying NOT NULL,
    visible boolean NOT NULL,
    remark character varying(500) DEFAULT NULL::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE infra_config; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.infra_config IS '参数配置表';


--
-- Name: COLUMN infra_config.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_config.id IS '参数主键';


--
-- Name: COLUMN infra_config.category; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_config.category IS '参数分组';


--
-- Name: COLUMN infra_config.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_config.type IS '参数类型';


--
-- Name: COLUMN infra_config.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_config.name IS '参数名称';


--
-- Name: COLUMN infra_config.config_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_config.config_key IS '参数键名';


--
-- Name: COLUMN infra_config.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_config.value IS '参数键值';


--
-- Name: COLUMN infra_config.visible; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_config.visible IS '是否可见';


--
-- Name: COLUMN infra_config.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_config.remark IS '备注';


--
-- Name: COLUMN infra_config.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_config.creator IS '创建者';


--
-- Name: COLUMN infra_config.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_config.create_time IS '创建时间';


--
-- Name: COLUMN infra_config.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_config.updater IS '更新者';


--
-- Name: COLUMN infra_config.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_config.update_time IS '更新时间';


--
-- Name: COLUMN infra_config.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_config.deleted IS '是否删除';


--
-- Name: infra_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.infra_config_seq
    START WITH 14
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: infra_file; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.infra_file (
    id bigint NOT NULL,
    config_id bigint,
    name character varying(256) DEFAULT NULL::character varying,
    path character varying(512) NOT NULL,
    url character varying(1024) NOT NULL,
    type character varying(128) DEFAULT NULL::character varying,
    size integer NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE infra_file; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.infra_file IS '文件表';


--
-- Name: COLUMN infra_file.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file.id IS '文件编号';


--
-- Name: COLUMN infra_file.config_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file.config_id IS '配置编号';


--
-- Name: COLUMN infra_file.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file.name IS '文件名';


--
-- Name: COLUMN infra_file.path; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file.path IS '文件路径';


--
-- Name: COLUMN infra_file.url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file.url IS '文件 URL';


--
-- Name: COLUMN infra_file.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file.type IS '文件类型';


--
-- Name: COLUMN infra_file.size; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file.size IS '文件大小';


--
-- Name: COLUMN infra_file.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file.creator IS '创建者';


--
-- Name: COLUMN infra_file.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file.create_time IS '创建时间';


--
-- Name: COLUMN infra_file.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file.updater IS '更新者';


--
-- Name: COLUMN infra_file.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file.update_time IS '更新时间';


--
-- Name: COLUMN infra_file.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file.deleted IS '是否删除';


--
-- Name: infra_file_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.infra_file_config (
    id bigint NOT NULL,
    name character varying(63) NOT NULL,
    storage smallint NOT NULL,
    remark character varying(255) DEFAULT NULL::character varying,
    master boolean NOT NULL,
    config character varying(4096) NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE infra_file_config; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.infra_file_config IS '文件配置表';


--
-- Name: COLUMN infra_file_config.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_config.id IS '编号';


--
-- Name: COLUMN infra_file_config.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_config.name IS '配置名';


--
-- Name: COLUMN infra_file_config.storage; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_config.storage IS '存储器';


--
-- Name: COLUMN infra_file_config.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_config.remark IS '备注';


--
-- Name: COLUMN infra_file_config.master; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_config.master IS '是否为主配置';


--
-- Name: COLUMN infra_file_config.config; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_config.config IS '存储配置';


--
-- Name: COLUMN infra_file_config.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_config.creator IS '创建者';


--
-- Name: COLUMN infra_file_config.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_config.create_time IS '创建时间';


--
-- Name: COLUMN infra_file_config.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_config.updater IS '更新者';


--
-- Name: COLUMN infra_file_config.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_config.update_time IS '更新时间';


--
-- Name: COLUMN infra_file_config.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_config.deleted IS '是否删除';


--
-- Name: infra_file_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.infra_file_config_seq
    START WITH 36
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: infra_file_content; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.infra_file_content (
    id bigint NOT NULL,
    config_id bigint NOT NULL,
    path character varying(512) NOT NULL,
    content bytea NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE infra_file_content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.infra_file_content IS '文件表';


--
-- Name: COLUMN infra_file_content.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_content.id IS '编号';


--
-- Name: COLUMN infra_file_content.config_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_content.config_id IS '配置编号';


--
-- Name: COLUMN infra_file_content.path; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_content.path IS '文件路径';


--
-- Name: COLUMN infra_file_content.content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_content.content IS '文件内容';


--
-- Name: COLUMN infra_file_content.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_content.creator IS '创建者';


--
-- Name: COLUMN infra_file_content.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_content.create_time IS '创建时间';


--
-- Name: COLUMN infra_file_content.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_content.updater IS '更新者';


--
-- Name: COLUMN infra_file_content.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_content.update_time IS '更新时间';


--
-- Name: COLUMN infra_file_content.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_file_content.deleted IS '是否删除';


--
-- Name: infra_file_content_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.infra_file_content_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: infra_file_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.infra_file_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: infra_job; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.infra_job (
    id bigint NOT NULL,
    name character varying(32) NOT NULL,
    status smallint NOT NULL,
    handler_name character varying(64) NOT NULL,
    handler_param character varying(255) DEFAULT NULL::character varying,
    cron_expression character varying(32) NOT NULL,
    retry_count integer DEFAULT 0 NOT NULL,
    retry_interval integer DEFAULT 0 NOT NULL,
    monitor_timeout integer DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE infra_job; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.infra_job IS '定时任务表';


--
-- Name: COLUMN infra_job.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job.id IS '任务编号';


--
-- Name: COLUMN infra_job.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job.name IS '任务名称';


--
-- Name: COLUMN infra_job.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job.status IS '任务状态';


--
-- Name: COLUMN infra_job.handler_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job.handler_name IS '处理器的名字';


--
-- Name: COLUMN infra_job.handler_param; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job.handler_param IS '处理器的参数';


--
-- Name: COLUMN infra_job.cron_expression; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job.cron_expression IS 'CRON 表达式';


--
-- Name: COLUMN infra_job.retry_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job.retry_count IS '重试次数';


--
-- Name: COLUMN infra_job.retry_interval; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job.retry_interval IS '重试间隔';


--
-- Name: COLUMN infra_job.monitor_timeout; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job.monitor_timeout IS '监控超时时间';


--
-- Name: COLUMN infra_job.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job.creator IS '创建者';


--
-- Name: COLUMN infra_job.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job.create_time IS '创建时间';


--
-- Name: COLUMN infra_job.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job.updater IS '更新者';


--
-- Name: COLUMN infra_job.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job.update_time IS '更新时间';


--
-- Name: COLUMN infra_job.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job.deleted IS '是否删除';


--
-- Name: infra_job_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.infra_job_log (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    handler_name character varying(64) NOT NULL,
    handler_param character varying(255) DEFAULT NULL::character varying,
    execute_index smallint DEFAULT 1 NOT NULL,
    begin_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone,
    duration integer,
    status smallint NOT NULL,
    result character varying(4000) DEFAULT ''::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE infra_job_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.infra_job_log IS '定时任务日志表';


--
-- Name: COLUMN infra_job_log.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.id IS '日志编号';


--
-- Name: COLUMN infra_job_log.job_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.job_id IS '任务编号';


--
-- Name: COLUMN infra_job_log.handler_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.handler_name IS '处理器的名字';


--
-- Name: COLUMN infra_job_log.handler_param; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.handler_param IS '处理器的参数';


--
-- Name: COLUMN infra_job_log.execute_index; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.execute_index IS '第几次执行';


--
-- Name: COLUMN infra_job_log.begin_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.begin_time IS '开始执行时间';


--
-- Name: COLUMN infra_job_log.end_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.end_time IS '结束执行时间';


--
-- Name: COLUMN infra_job_log.duration; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.duration IS '执行时长';


--
-- Name: COLUMN infra_job_log.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.status IS '任务状态';


--
-- Name: COLUMN infra_job_log.result; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.result IS '结果数据';


--
-- Name: COLUMN infra_job_log.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.creator IS '创建者';


--
-- Name: COLUMN infra_job_log.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.create_time IS '创建时间';


--
-- Name: COLUMN infra_job_log.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.updater IS '更新者';


--
-- Name: COLUMN infra_job_log.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.update_time IS '更新时间';


--
-- Name: COLUMN infra_job_log.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.infra_job_log.deleted IS '是否删除';


--
-- Name: infra_job_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.infra_job_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: infra_job_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.infra_job_seq
    START WITH 41
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_alert_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_alert_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_alert_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_alert_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_data_bridge_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_data_bridge_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_data_rule_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_data_rule_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_device_group_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_device_group_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_device_modbus_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_device_modbus_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_device_modbus_point_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_device_modbus_point_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_device_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_device_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_ota_firmware_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_ota_firmware_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_ota_task_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_ota_task_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_ota_task_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_ota_task_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_product_category_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_product_category_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_product_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_product_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_scene_rule_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_scene_rule_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iot_thing_model_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.iot_thing_model_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_address_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_address_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_experience_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_experience_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_group_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_group_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_level_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_level_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_level_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_level_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_point_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_point_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_sign_in_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_sign_in_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_sign_in_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_sign_in_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_tag_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_tag_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_user (
    id bigint NOT NULL,
    mobile text,
    email text,
    password text,
    status integer,
    register_ip text,
    register_terminal integer,
    login_ip text,
    login_date timestamp without time zone,
    nickname text,
    avatar text,
    name text,
    sex integer,
    birthday timestamp without time zone,
    area_id integer,
    mark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    username character varying(64)
);


--
-- Name: COLUMN member_user.username; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.member_user.username IS '订货账号（订货人的登录名，就是订货人名字，如张三；唯一）';


--
-- Name: member_user_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_user_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_user_store; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_user_store (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    sort integer DEFAULT 0 NOT NULL,
    status smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT now() NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT now() NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE member_user_store; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.member_user_store IS '订货账号授权门店：账号可给哪些门店下单（加盟店账号一条，片区订货管理人多条）';


--
-- Name: COLUMN member_user_store.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.member_user_store.user_id IS '订货账号编号（member_user.id）';


--
-- Name: COLUMN member_user_store.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.member_user_store.customer_id IS '被授权门店（erp_customer.id；必须是组织架构里的门店节点，且未闭店）';


--
-- Name: COLUMN member_user_store.is_default; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.member_user_store.is_default IS '账号默认门店：H5 首次进入用它，用户手动切换后以本地记忆为准';


--
-- Name: COLUMN member_user_store.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.member_user_store.status IS '状态：0 启用 / 1 停用';


--
-- Name: member_user_store_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_user_store_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_cal_holiday_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_cal_holiday_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_cal_plan_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_cal_plan_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_cal_plan_shift_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_cal_plan_shift_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_cal_plan_team_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_cal_plan_team_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_cal_team_member_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_cal_team_member_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_cal_team_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_cal_team_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_cal_team_shift_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_cal_team_shift_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_dv_check_plan_machinery_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_dv_check_plan_machinery_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_dv_check_plan_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_dv_check_plan_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_dv_check_plan_subject_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_dv_check_plan_subject_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_dv_check_record_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_dv_check_record_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_dv_check_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_dv_check_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_dv_machinery_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_dv_machinery_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_dv_machinery_type_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_dv_machinery_type_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_dv_mainten_record_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_dv_mainten_record_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_dv_mainten_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_dv_mainten_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_dv_repair_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_dv_repair_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_dv_repair_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_dv_repair_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_dv_subject_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_dv_subject_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_auto_code_part_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_auto_code_part_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_auto_code_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_auto_code_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_auto_code_rule_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_auto_code_rule_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_client_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_client_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_item_batch_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_item_batch_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_item_type_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_item_type_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_product_bom_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_product_bom_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_product_sip_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_product_sip_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_product_sop_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_product_sop_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_unit_measure_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_unit_measure_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_vendor_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_vendor_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_workshop_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_workshop_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_workstation_machine_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_workstation_machine_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_workstation_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_workstation_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_workstation_tool_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_workstation_tool_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_md_workstation_worker_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_md_workstation_worker_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_andon_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_andon_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_andon_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_andon_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_card_process_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_card_process_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_card_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_card_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_feedback_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_feedback_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_process_content_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_process_content_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_process_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_process_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_route_process_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_route_process_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_route_product_bom_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_route_product_bom_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_route_product_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_route_product_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_route_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_route_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_task_issue_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_task_issue_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_task_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_task_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_work_order_bom_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_work_order_bom_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_work_order_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_work_order_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_work_record_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_work_record_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_pro_work_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_pro_work_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_defect_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_defect_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_defect_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_defect_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_indicator_result_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_indicator_result_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_indicator_result_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_indicator_result_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_indicator_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_indicator_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_ipqc_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_ipqc_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_ipqc_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_ipqc_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_iqc_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_iqc_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_iqc_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_iqc_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_oqc_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_oqc_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_oqc_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_oqc_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_rqc_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_rqc_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_rqc_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_rqc_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_template_indicator_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_template_indicator_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_template_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_template_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_qc_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_qc_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_tm_tool_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_tm_tool_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_tm_tool_type_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_tm_tool_type_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_arrival_notice_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_arrival_notice_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_arrival_notice_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_arrival_notice_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_barcode_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_barcode_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_barcode_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_barcode_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_batch_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_batch_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_item_consume_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_item_consume_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_item_consume_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_item_consume_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_item_consume_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_item_consume_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_item_receipt_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_item_receipt_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_item_receipt_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_item_receipt_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_item_receipt_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_item_receipt_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_material_stock_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_material_stock_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_misc_issue_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_misc_issue_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_misc_issue_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_misc_issue_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_misc_issue_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_misc_issue_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_misc_receipt_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_misc_receipt_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_misc_receipt_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_misc_receipt_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_misc_receipt_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_misc_receipt_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_outsource_issue_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_outsource_issue_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_outsource_issue_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_outsource_issue_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_outsource_issue_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_outsource_issue_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_outsource_receipt_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_outsource_receipt_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_outsource_receipt_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_outsource_receipt_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_outsource_receipt_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_outsource_receipt_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_package_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_package_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_package_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_package_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_product_issue_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_product_issue_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_product_issue_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_product_issue_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_product_issue_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_product_issue_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_product_produce_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_product_produce_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_product_produce_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_product_produce_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_product_produce_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_product_produce_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_product_receipt_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_product_receipt_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_product_receipt_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_product_receipt_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_product_receipt_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_product_receipt_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_product_sales_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_product_sales_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_product_sales_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_product_sales_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_product_sales_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_product_sales_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_return_issue_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_return_issue_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_return_issue_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_return_issue_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_return_issue_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_return_issue_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_return_sales_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_return_sales_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_return_sales_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_return_sales_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_return_sales_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_return_sales_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_return_vendor_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_return_vendor_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_return_vendor_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_return_vendor_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_return_vendor_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_return_vendor_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_sales_notice_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_sales_notice_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_sales_notice_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_sales_notice_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_sn_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_sn_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_stock_taking_plan_param_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_stock_taking_plan_param_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_stock_taking_plan_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_stock_taking_plan_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_stock_taking_task_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_stock_taking_task_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_stock_taking_task_result_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_stock_taking_task_result_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_stock_taking_task_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_stock_taking_task_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_transaction_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_transaction_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_transfer_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_transfer_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_transfer_line_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_transfer_line_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_transfer_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_transfer_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_warehouse_area_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_warehouse_area_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_warehouse_location_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_warehouse_location_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mes_wm_warehouse_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mes_wm_warehouse_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mp_account_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mp_account_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mp_auto_reply_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mp_auto_reply_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mp_material_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mp_material_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mp_menu_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mp_menu_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mp_message_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mp_message_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mp_message_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mp_message_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mp_tag_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mp_tag_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mp_user_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mp_user_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_app_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_app_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_channel_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_channel_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_demo_order_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_demo_order_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_demo_withdraw_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_demo_withdraw_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_notify_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_notify_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_notify_task_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_notify_task_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_order_extension_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_order_extension_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_order_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_order_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_refund_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_refund_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_transfer_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_transfer_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_wallet_recharge_package_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_wallet_recharge_package_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_wallet_recharge_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_wallet_recharge_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_wallet_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_wallet_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_wallet_transaction_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_wallet_transaction_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_iteration_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_iteration_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_content_permission_member_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_content_permission_member_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_content_permission_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_content_permission_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_document_comment_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_document_comment_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_document_label_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_document_label_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_document_like_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_document_like_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_document_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_document_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_document_share_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_document_share_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_favorite_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_favorite_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_folder_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_folder_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_group_relation_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_group_relation_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_group_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_group_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_library_member_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_library_member_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_library_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_library_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_library_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_library_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_recycle_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_recycle_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_knowledge_view_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_knowledge_view_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_project_announcement_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_project_announcement_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_project_favorite_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_project_favorite_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_project_group_relation_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_project_group_relation_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_project_group_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_project_group_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_project_member_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_project_member_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_project_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_project_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_project_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_project_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_work_item_activity_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_work_item_activity_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_work_item_board_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_work_item_board_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_work_item_comment_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_work_item_comment_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_work_item_label_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_work_item_label_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_work_item_member_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_work_item_member_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_work_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_work_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_work_item_status_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_work_item_status_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_work_item_user_sort_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_work_item_user_sort_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pms_work_item_work_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pms_work_item_work_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_brand; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_brand (
    id bigint NOT NULL,
    name text,
    pic_url text,
    sort integer,
    description text,
    status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: product_brand_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_brand_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_browse_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_browse_history (
    id bigint NOT NULL,
    spu_id bigint,
    user_id bigint,
    user_deleted boolean,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: product_browse_history_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_browse_history_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_category (
    id bigint NOT NULL,
    parent_id bigint,
    name text,
    pic_url text,
    sort integer,
    status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: product_category_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_category_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_comment_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_comment_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_favorite; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_favorite (
    id bigint NOT NULL,
    user_id bigint,
    spu_id bigint,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: product_favorite_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_favorite_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_property; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_property (
    id bigint NOT NULL,
    name text,
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: product_property_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_property_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_property_value; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_property_value (
    id bigint NOT NULL,
    property_id bigint,
    name text,
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: product_property_value_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_property_value_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_sku; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_sku (
    id bigint NOT NULL,
    spu_id bigint,
    properties text,
    price integer,
    market_price integer,
    cost_price integer,
    bar_code text,
    pic_url text,
    stock integer,
    weight double precision,
    volume double precision,
    sales_count integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    erp_product_id bigint
);


--
-- Name: COLUMN product_sku.erp_product_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_sku.erp_product_id IS '对应的 ERP 物料 erp_product.id（1 物料 : 1 SKU，唯一）；为空表示未关联（非订货商品）。取代原先按 bar_code 字符串 join 的隐式约定';


--
-- Name: product_sku_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_sku_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_spu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_spu (
    id bigint NOT NULL,
    name text,
    keyword text,
    introduction text,
    description text,
    category_id bigint,
    brand_id bigint,
    pic_url text,
    slider_pic_urls text,
    sort integer,
    status integer,
    spec_type boolean,
    price integer,
    market_price integer,
    cost_price integer,
    stock integer,
    delivery_template_id bigint,
    give_integral integer,
    sub_commission_type boolean,
    sales_count integer,
    virtual_sales_count integer,
    browse_count integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    code character varying(32)
);


--
-- Name: COLUMN product_spu.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_spu.code IS '物料（商品）编码（规则 WL + 6 位流水；租户内唯一）';


--
-- Name: product_spu_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_spu_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_statistics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_statistics (
    id bigint NOT NULL,
    "time" date,
    spu_id bigint,
    browse_count integer,
    browse_user_count integer,
    favorite_count integer,
    cart_count integer,
    order_count integer,
    order_pay_count integer,
    order_pay_price integer,
    after_sale_count integer,
    after_sale_refund_price integer,
    browse_convert_percent integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: product_statistics_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_statistics_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_article_category_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_article_category_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_article_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_article_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_banner_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_banner_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_bargain_activity_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_bargain_activity_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_bargain_help_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_bargain_help_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_bargain_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_bargain_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_combination_activity_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_combination_activity_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_combination_product_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_combination_product_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_combination_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_combination_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_coupon_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_coupon_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_coupon_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_coupon_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_discount_activity_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_discount_activity_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_discount_product_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_discount_product_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_diy_page_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_diy_page_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_diy_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_diy_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_kefu_conversation_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_kefu_conversation_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_kefu_message_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_kefu_message_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_point_activity_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_point_activity_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_point_product_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_point_product_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_reward_activity_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_reward_activity_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_seckill_activity_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_seckill_activity_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_seckill_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_seckill_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_seckill_product_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_seckill_product_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: qrtz_blob_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_blob_triggers (
    sched_name character varying(120) NOT NULL,
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    blob_data bytea
);


--
-- Name: qrtz_calendars; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_calendars (
    sched_name character varying(120) NOT NULL,
    calendar_name character varying(200) NOT NULL,
    calendar bytea NOT NULL
);


--
-- Name: qrtz_cron_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_cron_triggers (
    sched_name character varying(120) NOT NULL,
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    cron_expression character varying(120) NOT NULL,
    time_zone_id character varying(80)
);


--
-- Name: qrtz_fired_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_fired_triggers (
    sched_name character varying(120) NOT NULL,
    entry_id character varying(95) NOT NULL,
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    instance_name character varying(200) NOT NULL,
    fired_time bigint NOT NULL,
    sched_time bigint NOT NULL,
    priority integer NOT NULL,
    state character varying(16) NOT NULL,
    job_name character varying(200),
    job_group character varying(200),
    is_nonconcurrent boolean,
    requests_recovery boolean
);


--
-- Name: qrtz_job_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_job_details (
    sched_name character varying(120) NOT NULL,
    job_name character varying(200) NOT NULL,
    job_group character varying(200) NOT NULL,
    description character varying(250),
    job_class_name character varying(250) NOT NULL,
    is_durable boolean NOT NULL,
    is_nonconcurrent boolean NOT NULL,
    is_update_data boolean NOT NULL,
    requests_recovery boolean NOT NULL,
    job_data bytea
);


--
-- Name: qrtz_locks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_locks (
    sched_name character varying(120) NOT NULL,
    lock_name character varying(40) NOT NULL
);


--
-- Name: qrtz_paused_trigger_grps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_paused_trigger_grps (
    sched_name character varying(120) NOT NULL,
    trigger_group character varying(200) NOT NULL
);


--
-- Name: qrtz_scheduler_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_scheduler_state (
    sched_name character varying(120) NOT NULL,
    instance_name character varying(200) NOT NULL,
    last_checkin_time bigint NOT NULL,
    checkin_interval bigint NOT NULL
);


--
-- Name: qrtz_simple_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_simple_triggers (
    sched_name character varying(120) NOT NULL,
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    repeat_count bigint NOT NULL,
    repeat_interval bigint NOT NULL,
    times_triggered bigint NOT NULL
);


--
-- Name: qrtz_simprop_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_simprop_triggers (
    sched_name character varying(120) NOT NULL,
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    str_prop_1 character varying(512),
    str_prop_2 character varying(512),
    str_prop_3 character varying(512),
    int_prop_1 integer,
    int_prop_2 integer,
    long_prop_1 bigint,
    long_prop_2 bigint,
    dec_prop_1 numeric(13,4),
    dec_prop_2 numeric(13,4),
    bool_prop_1 boolean,
    bool_prop_2 boolean
);


--
-- Name: qrtz_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_triggers (
    sched_name character varying(120) NOT NULL,
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    job_name character varying(200) NOT NULL,
    job_group character varying(200) NOT NULL,
    description character varying(250),
    next_fire_time bigint,
    prev_fire_time bigint,
    priority integer,
    trigger_state character varying(16) NOT NULL,
    trigger_type character varying(8) NOT NULL,
    start_time bigint NOT NULL,
    end_time bigint,
    calendar_name character varying(200),
    misfire_instr smallint,
    job_data bytea
);


--
-- Name: report_go_view_project_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.report_go_view_project_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_code_rule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_code_rule (
    id bigint NOT NULL,
    rule_key character varying(64) NOT NULL,
    name character varying(64) NOT NULL,
    prefix character varying(16) NOT NULL,
    seq_length smallint DEFAULT 6 NOT NULL,
    current_value bigint DEFAULT 0 NOT NULL,
    remark character varying(255) DEFAULT ''::character varying,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT now() NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT now() NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_code_rule; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_code_rule IS '编码规则：主数据的业务编码前缀与流水（对齐金蝶的「编码规则」）';


--
-- Name: COLUMN system_code_rule.rule_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_code_rule.rule_key IS '规则标识，与主数据对象一一对应，如 erp_customer';


--
-- Name: COLUMN system_code_rule.prefix; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_code_rule.prefix IS '编码前缀，如 KH';


--
-- Name: COLUMN system_code_rule.seq_length; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_code_rule.seq_length IS '流水号长度（左补零），如 6 → KH000001';


--
-- Name: COLUMN system_code_rule.current_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_code_rule.current_value IS '当前已分配到的流水值';


--
-- Name: system_code_rule_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_code_rule_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_dept; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_dept (
    id bigint NOT NULL,
    name character varying(30) DEFAULT ''::character varying NOT NULL,
    parent_id bigint DEFAULT 0 NOT NULL,
    sort integer DEFAULT 0 NOT NULL,
    leader_user_id bigint,
    phone character varying(11) DEFAULT NULL::character varying,
    email character varying(50) DEFAULT NULL::character varying,
    status smallint NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    dept_type character varying(20) DEFAULT 'ORG'::character varying NOT NULL,
    business_status smallint DEFAULT 0 NOT NULL,
    closed_time timestamp without time zone,
    closed_reason character varying(255),
    code character varying(32)
);


--
-- Name: TABLE system_dept; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_dept IS '部门表';


--
-- Name: COLUMN system_dept.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.id IS '部门id';


--
-- Name: COLUMN system_dept.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.name IS '部门名称';


--
-- Name: COLUMN system_dept.parent_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.parent_id IS '父部门id';


--
-- Name: COLUMN system_dept.sort; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.sort IS '显示顺序';


--
-- Name: COLUMN system_dept.leader_user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.leader_user_id IS '负责人';


--
-- Name: COLUMN system_dept.phone; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.phone IS '联系电话';


--
-- Name: COLUMN system_dept.email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.email IS '邮箱';


--
-- Name: COLUMN system_dept.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.status IS '部门状态（0正常 1停用）';


--
-- Name: COLUMN system_dept.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.creator IS '创建者';


--
-- Name: COLUMN system_dept.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.create_time IS '创建时间';


--
-- Name: COLUMN system_dept.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.updater IS '更新者';


--
-- Name: COLUMN system_dept.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.update_time IS '更新时间';


--
-- Name: COLUMN system_dept.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.deleted IS '是否删除';


--
-- Name: COLUMN system_dept.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.tenant_id IS '租户编号';


--
-- Name: COLUMN system_dept.dept_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.dept_type IS '节点类型：ORG 组织 / STORE 门店（字典 system_dept_type）';


--
-- Name: COLUMN system_dept.business_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.business_status IS '营业状态（仅门店有意义）：0 营业 / 1 已闭店（字典 system_dept_business_status）';


--
-- Name: COLUMN system_dept.closed_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.closed_time IS '闭店时间（复开时清空）';


--
-- Name: COLUMN system_dept.closed_reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.closed_reason IS '闭店原因';


--
-- Name: COLUMN system_dept.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dept.code IS '组织节点编码（规则 BM + 4 位流水；租户内唯一）';


--
-- Name: system_dept_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_dept_seq
    START WITH 118
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_dict_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_dict_data (
    id bigint NOT NULL,
    sort integer DEFAULT 0 NOT NULL,
    label character varying(100) DEFAULT ''::character varying NOT NULL,
    value character varying(100) DEFAULT ''::character varying NOT NULL,
    dict_type character varying(100) DEFAULT ''::character varying NOT NULL,
    status smallint DEFAULT 0 NOT NULL,
    color_type character varying(100) DEFAULT ''::character varying,
    css_class character varying(100) DEFAULT ''::character varying,
    remark character varying(500) DEFAULT NULL::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_dict_data; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_dict_data IS '字典数据表';


--
-- Name: COLUMN system_dict_data.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_data.id IS '字典编码';


--
-- Name: COLUMN system_dict_data.sort; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_data.sort IS '字典排序';


--
-- Name: COLUMN system_dict_data.label; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_data.label IS '字典标签';


--
-- Name: COLUMN system_dict_data.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_data.value IS '字典键值';


--
-- Name: COLUMN system_dict_data.dict_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_data.dict_type IS '字典类型';


--
-- Name: COLUMN system_dict_data.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_data.status IS '状态（0正常 1停用）';


--
-- Name: COLUMN system_dict_data.color_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_data.color_type IS '颜色类型';


--
-- Name: COLUMN system_dict_data.css_class; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_data.css_class IS 'css 样式';


--
-- Name: COLUMN system_dict_data.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_data.remark IS '备注';


--
-- Name: COLUMN system_dict_data.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_data.creator IS '创建者';


--
-- Name: COLUMN system_dict_data.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_data.create_time IS '创建时间';


--
-- Name: COLUMN system_dict_data.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_data.updater IS '更新者';


--
-- Name: COLUMN system_dict_data.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_data.update_time IS '更新时间';


--
-- Name: COLUMN system_dict_data.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_data.deleted IS '是否删除';


--
-- Name: system_dict_data_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_dict_data_seq
    START WITH 3449
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_dict_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_dict_type (
    id bigint NOT NULL,
    name character varying(100) DEFAULT ''::character varying NOT NULL,
    type character varying(100) DEFAULT ''::character varying NOT NULL,
    status smallint DEFAULT 0 NOT NULL,
    remark character varying(500) DEFAULT NULL::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    deleted_time timestamp without time zone
);


--
-- Name: TABLE system_dict_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_dict_type IS '字典类型表';


--
-- Name: COLUMN system_dict_type.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_type.id IS '字典主键';


--
-- Name: COLUMN system_dict_type.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_type.name IS '字典名称';


--
-- Name: COLUMN system_dict_type.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_type.type IS '字典类型';


--
-- Name: COLUMN system_dict_type.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_type.status IS '状态（0正常 1停用）';


--
-- Name: COLUMN system_dict_type.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_type.remark IS '备注';


--
-- Name: COLUMN system_dict_type.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_type.creator IS '创建者';


--
-- Name: COLUMN system_dict_type.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_type.create_time IS '创建时间';


--
-- Name: COLUMN system_dict_type.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_type.updater IS '更新者';


--
-- Name: COLUMN system_dict_type.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_type.update_time IS '更新时间';


--
-- Name: COLUMN system_dict_type.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_type.deleted IS '是否删除';


--
-- Name: COLUMN system_dict_type.deleted_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_dict_type.deleted_time IS '删除时间';


--
-- Name: system_dict_type_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_dict_type_seq
    START WITH 2139
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_login_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_login_log (
    id bigint NOT NULL,
    log_type bigint NOT NULL,
    trace_id character varying(64) DEFAULT ''::character varying NOT NULL,
    user_id bigint DEFAULT 0 NOT NULL,
    user_type smallint DEFAULT 0 NOT NULL,
    username character varying(50) DEFAULT ''::character varying NOT NULL,
    result smallint NOT NULL,
    user_ip character varying(50) NOT NULL,
    user_agent character varying(512) NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_login_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_login_log IS '系统访问记录';


--
-- Name: COLUMN system_login_log.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.id IS '访问ID';


--
-- Name: COLUMN system_login_log.log_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.log_type IS '日志类型';


--
-- Name: COLUMN system_login_log.trace_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.trace_id IS '链路追踪编号';


--
-- Name: COLUMN system_login_log.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.user_id IS '用户编号';


--
-- Name: COLUMN system_login_log.user_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.user_type IS '用户类型';


--
-- Name: COLUMN system_login_log.username; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.username IS '用户账号';


--
-- Name: COLUMN system_login_log.result; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.result IS '登陆结果';


--
-- Name: COLUMN system_login_log.user_ip; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.user_ip IS '用户 IP';


--
-- Name: COLUMN system_login_log.user_agent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.user_agent IS '浏览器 UA';


--
-- Name: COLUMN system_login_log.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.creator IS '创建者';


--
-- Name: COLUMN system_login_log.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.create_time IS '创建时间';


--
-- Name: COLUMN system_login_log.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.updater IS '更新者';


--
-- Name: COLUMN system_login_log.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.update_time IS '更新时间';


--
-- Name: COLUMN system_login_log.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.deleted IS '是否删除';


--
-- Name: COLUMN system_login_log.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_login_log.tenant_id IS '租户编号';


--
-- Name: system_login_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_login_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_mail_account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_mail_account (
    id bigint NOT NULL,
    mail character varying(255) NOT NULL,
    username character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    host character varying(255) NOT NULL,
    port integer NOT NULL,
    ssl_enable boolean DEFAULT false NOT NULL,
    starttls_enable boolean DEFAULT false NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_mail_account; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_mail_account IS '邮箱账号表';


--
-- Name: COLUMN system_mail_account.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_account.id IS '主键';


--
-- Name: COLUMN system_mail_account.mail; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_account.mail IS '邮箱';


--
-- Name: COLUMN system_mail_account.username; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_account.username IS '用户名';


--
-- Name: COLUMN system_mail_account.password; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_account.password IS '密码';


--
-- Name: COLUMN system_mail_account.host; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_account.host IS 'SMTP 服务器域名';


--
-- Name: COLUMN system_mail_account.port; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_account.port IS 'SMTP 服务器端口';


--
-- Name: COLUMN system_mail_account.ssl_enable; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_account.ssl_enable IS '是否开启 SSL';


--
-- Name: COLUMN system_mail_account.starttls_enable; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_account.starttls_enable IS '是否开启 STARTTLS';


--
-- Name: COLUMN system_mail_account.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_account.creator IS '创建者';


--
-- Name: COLUMN system_mail_account.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_account.create_time IS '创建时间';


--
-- Name: COLUMN system_mail_account.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_account.updater IS '更新者';


--
-- Name: COLUMN system_mail_account.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_account.update_time IS '更新时间';


--
-- Name: COLUMN system_mail_account.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_account.deleted IS '是否删除';


--
-- Name: system_mail_account_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_mail_account_seq
    START WITH 5
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_mail_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_mail_log (
    id bigint NOT NULL,
    user_id bigint,
    user_type smallint,
    to_mails character varying(1024) NOT NULL,
    cc_mails character varying(1024) DEFAULT NULL::character varying,
    bcc_mails character varying(1024) DEFAULT NULL::character varying,
    account_id bigint NOT NULL,
    from_mail character varying(255) NOT NULL,
    template_id bigint NOT NULL,
    template_code character varying(63) NOT NULL,
    template_nickname character varying(255) DEFAULT NULL::character varying,
    template_title character varying(255) NOT NULL,
    template_content text NOT NULL,
    template_params character varying(255) NOT NULL,
    send_status smallint DEFAULT 0 NOT NULL,
    send_time timestamp without time zone,
    send_message_id character varying(255) DEFAULT NULL::character varying,
    send_exception character varying(4096) DEFAULT NULL::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_mail_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_mail_log IS '邮件日志表';


--
-- Name: COLUMN system_mail_log.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.id IS '编号';


--
-- Name: COLUMN system_mail_log.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.user_id IS '用户编号';


--
-- Name: COLUMN system_mail_log.user_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.user_type IS '用户类型';


--
-- Name: COLUMN system_mail_log.to_mails; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.to_mails IS '接收邮箱地址';


--
-- Name: COLUMN system_mail_log.cc_mails; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.cc_mails IS '抄送邮箱地址';


--
-- Name: COLUMN system_mail_log.bcc_mails; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.bcc_mails IS '密送邮箱地址';


--
-- Name: COLUMN system_mail_log.account_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.account_id IS '邮箱账号编号';


--
-- Name: COLUMN system_mail_log.from_mail; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.from_mail IS '发送邮箱地址';


--
-- Name: COLUMN system_mail_log.template_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.template_id IS '模板编号';


--
-- Name: COLUMN system_mail_log.template_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.template_code IS '模板编码';


--
-- Name: COLUMN system_mail_log.template_nickname; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.template_nickname IS '模版发送人名称';


--
-- Name: COLUMN system_mail_log.template_title; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.template_title IS '邮件标题';


--
-- Name: COLUMN system_mail_log.template_content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.template_content IS '邮件内容';


--
-- Name: COLUMN system_mail_log.template_params; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.template_params IS '邮件参数';


--
-- Name: COLUMN system_mail_log.send_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.send_status IS '发送状态';


--
-- Name: COLUMN system_mail_log.send_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.send_time IS '发送时间';


--
-- Name: COLUMN system_mail_log.send_message_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.send_message_id IS '发送返回的消息 ID';


--
-- Name: COLUMN system_mail_log.send_exception; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.send_exception IS '发送异常';


--
-- Name: COLUMN system_mail_log.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.creator IS '创建者';


--
-- Name: COLUMN system_mail_log.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.create_time IS '创建时间';


--
-- Name: COLUMN system_mail_log.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.updater IS '更新者';


--
-- Name: COLUMN system_mail_log.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.update_time IS '更新时间';


--
-- Name: COLUMN system_mail_log.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_log.deleted IS '是否删除';


--
-- Name: system_mail_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_mail_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_mail_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_mail_template (
    id bigint NOT NULL,
    name character varying(63) NOT NULL,
    code character varying(63) NOT NULL,
    account_id bigint NOT NULL,
    nickname character varying(255) DEFAULT NULL::character varying,
    title character varying(255) NOT NULL,
    content character varying(10240) NOT NULL,
    params character varying(255) NOT NULL,
    status smallint NOT NULL,
    remark character varying(255) DEFAULT NULL::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_mail_template; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_mail_template IS '邮件模版表';


--
-- Name: COLUMN system_mail_template.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.id IS '编号';


--
-- Name: COLUMN system_mail_template.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.name IS '模板名称';


--
-- Name: COLUMN system_mail_template.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.code IS '模板编码';


--
-- Name: COLUMN system_mail_template.account_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.account_id IS '发送的邮箱账号编号';


--
-- Name: COLUMN system_mail_template.nickname; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.nickname IS '发送人名称';


--
-- Name: COLUMN system_mail_template.title; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.title IS '模板标题';


--
-- Name: COLUMN system_mail_template.content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.content IS '模板内容';


--
-- Name: COLUMN system_mail_template.params; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.params IS '参数数组';


--
-- Name: COLUMN system_mail_template.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.status IS '开启状态';


--
-- Name: COLUMN system_mail_template.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.remark IS '备注';


--
-- Name: COLUMN system_mail_template.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.creator IS '创建者';


--
-- Name: COLUMN system_mail_template.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.create_time IS '创建时间';


--
-- Name: COLUMN system_mail_template.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.updater IS '更新者';


--
-- Name: COLUMN system_mail_template.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.update_time IS '更新时间';


--
-- Name: COLUMN system_mail_template.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_mail_template.deleted IS '是否删除';


--
-- Name: system_mail_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_mail_template_seq
    START WITH 16
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_menu (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    permission character varying(100) DEFAULT ''::character varying NOT NULL,
    type smallint NOT NULL,
    sort integer DEFAULT 0 NOT NULL,
    parent_id bigint DEFAULT 0 NOT NULL,
    path character varying(200) DEFAULT ''::character varying,
    icon character varying(100) DEFAULT '#'::character varying,
    component character varying(255) DEFAULT NULL::character varying,
    component_name character varying(255) DEFAULT NULL::character varying,
    status smallint DEFAULT 0 NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    keep_alive boolean DEFAULT true NOT NULL,
    always_show boolean DEFAULT true NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_menu; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_menu IS '菜单权限表';


--
-- Name: COLUMN system_menu.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.id IS '菜单ID';


--
-- Name: COLUMN system_menu.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.name IS '菜单名称';


--
-- Name: COLUMN system_menu.permission; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.permission IS '权限标识';


--
-- Name: COLUMN system_menu.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.type IS '菜单类型';


--
-- Name: COLUMN system_menu.sort; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.sort IS '显示顺序';


--
-- Name: COLUMN system_menu.parent_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.parent_id IS '父菜单ID';


--
-- Name: COLUMN system_menu.path; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.path IS '路由地址';


--
-- Name: COLUMN system_menu.icon; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.icon IS '菜单图标';


--
-- Name: COLUMN system_menu.component; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.component IS '组件路径';


--
-- Name: COLUMN system_menu.component_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.component_name IS '组件名';


--
-- Name: COLUMN system_menu.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.status IS '菜单状态';


--
-- Name: COLUMN system_menu.visible; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.visible IS '是否可见';


--
-- Name: COLUMN system_menu.keep_alive; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.keep_alive IS '是否缓存';


--
-- Name: COLUMN system_menu.always_show; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.always_show IS '是否总是显示';


--
-- Name: COLUMN system_menu.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.creator IS '创建者';


--
-- Name: COLUMN system_menu.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.create_time IS '创建时间';


--
-- Name: COLUMN system_menu.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.updater IS '更新者';


--
-- Name: COLUMN system_menu.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.update_time IS '更新时间';


--
-- Name: COLUMN system_menu.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_menu.deleted IS '是否删除';


--
-- Name: system_menu_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_menu_seq
    START WITH 5986
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_notice; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_notice (
    id bigint NOT NULL,
    title character varying(50) NOT NULL,
    content text NOT NULL,
    type smallint NOT NULL,
    status smallint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_notice; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_notice IS '通知公告表';


--
-- Name: COLUMN system_notice.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notice.id IS '公告ID';


--
-- Name: COLUMN system_notice.title; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notice.title IS '公告标题';


--
-- Name: COLUMN system_notice.content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notice.content IS '公告内容';


--
-- Name: COLUMN system_notice.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notice.type IS '公告类型（1通知 2公告）';


--
-- Name: COLUMN system_notice.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notice.status IS '公告状态（0正常 1关闭）';


--
-- Name: COLUMN system_notice.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notice.creator IS '创建者';


--
-- Name: COLUMN system_notice.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notice.create_time IS '创建时间';


--
-- Name: COLUMN system_notice.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notice.updater IS '更新者';


--
-- Name: COLUMN system_notice.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notice.update_time IS '更新时间';


--
-- Name: COLUMN system_notice.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notice.deleted IS '是否删除';


--
-- Name: COLUMN system_notice.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notice.tenant_id IS '租户编号';


--
-- Name: system_notice_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_notice_seq
    START WITH 5
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_notify_message; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_notify_message (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    user_type smallint NOT NULL,
    template_id bigint NOT NULL,
    template_code character varying(64) NOT NULL,
    template_nickname character varying(63) NOT NULL,
    template_content character varying(1024) NOT NULL,
    template_type integer NOT NULL,
    template_params character varying(255) NOT NULL,
    read_status boolean NOT NULL,
    read_time timestamp without time zone,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_notify_message; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_notify_message IS '站内信消息表';


--
-- Name: COLUMN system_notify_message.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.id IS '用户ID';


--
-- Name: COLUMN system_notify_message.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.user_id IS '用户id';


--
-- Name: COLUMN system_notify_message.user_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.user_type IS '用户类型';


--
-- Name: COLUMN system_notify_message.template_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.template_id IS '模版编号';


--
-- Name: COLUMN system_notify_message.template_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.template_code IS '模板编码';


--
-- Name: COLUMN system_notify_message.template_nickname; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.template_nickname IS '模版发送人名称';


--
-- Name: COLUMN system_notify_message.template_content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.template_content IS '模版内容';


--
-- Name: COLUMN system_notify_message.template_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.template_type IS '模版类型';


--
-- Name: COLUMN system_notify_message.template_params; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.template_params IS '模版参数';


--
-- Name: COLUMN system_notify_message.read_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.read_status IS '是否已读';


--
-- Name: COLUMN system_notify_message.read_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.read_time IS '阅读时间';


--
-- Name: COLUMN system_notify_message.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.creator IS '创建者';


--
-- Name: COLUMN system_notify_message.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.create_time IS '创建时间';


--
-- Name: COLUMN system_notify_message.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.updater IS '更新者';


--
-- Name: COLUMN system_notify_message.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.update_time IS '更新时间';


--
-- Name: COLUMN system_notify_message.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.deleted IS '是否删除';


--
-- Name: COLUMN system_notify_message.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_message.tenant_id IS '租户编号';


--
-- Name: system_notify_message_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_notify_message_seq
    START WITH 11
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_notify_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_notify_template (
    id bigint NOT NULL,
    name character varying(63) NOT NULL,
    code character varying(64) NOT NULL,
    nickname character varying(255) NOT NULL,
    content character varying(1024) NOT NULL,
    type smallint NOT NULL,
    params character varying(255) DEFAULT NULL::character varying,
    status smallint NOT NULL,
    remark character varying(255) DEFAULT NULL::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_notify_template; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_notify_template IS '站内信模板表';


--
-- Name: COLUMN system_notify_template.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_template.id IS '主键';


--
-- Name: COLUMN system_notify_template.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_template.name IS '模板名称';


--
-- Name: COLUMN system_notify_template.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_template.code IS '模版编码';


--
-- Name: COLUMN system_notify_template.nickname; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_template.nickname IS '发送人名称';


--
-- Name: COLUMN system_notify_template.content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_template.content IS '模版内容';


--
-- Name: COLUMN system_notify_template.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_template.type IS '类型';


--
-- Name: COLUMN system_notify_template.params; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_template.params IS '参数数组';


--
-- Name: COLUMN system_notify_template.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_template.status IS '状态';


--
-- Name: COLUMN system_notify_template.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_template.remark IS '备注';


--
-- Name: COLUMN system_notify_template.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_template.creator IS '创建者';


--
-- Name: COLUMN system_notify_template.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_template.create_time IS '创建时间';


--
-- Name: COLUMN system_notify_template.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_template.updater IS '更新者';


--
-- Name: COLUMN system_notify_template.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_template.update_time IS '更新时间';


--
-- Name: COLUMN system_notify_template.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_notify_template.deleted IS '是否删除';


--
-- Name: system_notify_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_notify_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_oauth2_access_token; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_oauth2_access_token (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    user_type smallint NOT NULL,
    user_info character varying(512) NOT NULL,
    access_token character varying(255) NOT NULL,
    refresh_token character varying(32) NOT NULL,
    client_id character varying(255) NOT NULL,
    scopes character varying(255) DEFAULT NULL::character varying,
    expires_time timestamp without time zone NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_oauth2_access_token; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_oauth2_access_token IS 'OAuth2 访问令牌';


--
-- Name: COLUMN system_oauth2_access_token.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.id IS '编号';


--
-- Name: COLUMN system_oauth2_access_token.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.user_id IS '用户编号';


--
-- Name: COLUMN system_oauth2_access_token.user_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.user_type IS '用户类型';


--
-- Name: COLUMN system_oauth2_access_token.user_info; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.user_info IS '用户信息';


--
-- Name: COLUMN system_oauth2_access_token.access_token; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.access_token IS '访问令牌';


--
-- Name: COLUMN system_oauth2_access_token.refresh_token; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.refresh_token IS '刷新令牌';


--
-- Name: COLUMN system_oauth2_access_token.client_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.client_id IS '客户端编号';


--
-- Name: COLUMN system_oauth2_access_token.scopes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.scopes IS '授权范围';


--
-- Name: COLUMN system_oauth2_access_token.expires_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.expires_time IS '过期时间';


--
-- Name: COLUMN system_oauth2_access_token.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.creator IS '创建者';


--
-- Name: COLUMN system_oauth2_access_token.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.create_time IS '创建时间';


--
-- Name: COLUMN system_oauth2_access_token.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.updater IS '更新者';


--
-- Name: COLUMN system_oauth2_access_token.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.update_time IS '更新时间';


--
-- Name: COLUMN system_oauth2_access_token.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.deleted IS '是否删除';


--
-- Name: COLUMN system_oauth2_access_token.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_access_token.tenant_id IS '租户编号';


--
-- Name: system_oauth2_access_token_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_oauth2_access_token_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_oauth2_approve; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_oauth2_approve (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    user_type smallint NOT NULL,
    client_id character varying(255) NOT NULL,
    scope character varying(255) DEFAULT ''::character varying NOT NULL,
    approved boolean DEFAULT false NOT NULL,
    expires_time timestamp without time zone NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_oauth2_approve; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_oauth2_approve IS 'OAuth2 批准表';


--
-- Name: COLUMN system_oauth2_approve.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_approve.id IS '编号';


--
-- Name: COLUMN system_oauth2_approve.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_approve.user_id IS '用户编号';


--
-- Name: COLUMN system_oauth2_approve.user_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_approve.user_type IS '用户类型';


--
-- Name: COLUMN system_oauth2_approve.client_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_approve.client_id IS '客户端编号';


--
-- Name: COLUMN system_oauth2_approve.scope; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_approve.scope IS '授权范围';


--
-- Name: COLUMN system_oauth2_approve.approved; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_approve.approved IS '是否接受';


--
-- Name: COLUMN system_oauth2_approve.expires_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_approve.expires_time IS '过期时间';


--
-- Name: COLUMN system_oauth2_approve.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_approve.creator IS '创建者';


--
-- Name: COLUMN system_oauth2_approve.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_approve.create_time IS '创建时间';


--
-- Name: COLUMN system_oauth2_approve.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_approve.updater IS '更新者';


--
-- Name: COLUMN system_oauth2_approve.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_approve.update_time IS '更新时间';


--
-- Name: COLUMN system_oauth2_approve.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_approve.deleted IS '是否删除';


--
-- Name: COLUMN system_oauth2_approve.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_approve.tenant_id IS '租户编号';


--
-- Name: system_oauth2_approve_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_oauth2_approve_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_oauth2_client; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_oauth2_client (
    id bigint NOT NULL,
    client_id character varying(255) NOT NULL,
    secret character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    logo character varying(255) NOT NULL,
    description character varying(255) DEFAULT NULL::character varying,
    status smallint NOT NULL,
    access_token_validity_seconds integer NOT NULL,
    refresh_token_validity_seconds integer NOT NULL,
    redirect_uris character varying(255) NOT NULL,
    authorized_grant_types character varying(255) NOT NULL,
    scopes character varying(255) DEFAULT NULL::character varying,
    auto_approve_scopes character varying(255) DEFAULT NULL::character varying,
    authorities character varying(255) DEFAULT NULL::character varying,
    resource_ids character varying(255) DEFAULT NULL::character varying,
    additional_information character varying(4096) DEFAULT NULL::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_oauth2_client; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_oauth2_client IS 'OAuth2 客户端表';


--
-- Name: COLUMN system_oauth2_client.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.id IS '编号';


--
-- Name: COLUMN system_oauth2_client.client_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.client_id IS '客户端编号';


--
-- Name: COLUMN system_oauth2_client.secret; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.secret IS '客户端密钥';


--
-- Name: COLUMN system_oauth2_client.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.name IS '应用名';


--
-- Name: COLUMN system_oauth2_client.logo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.logo IS '应用图标';


--
-- Name: COLUMN system_oauth2_client.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.description IS '应用描述';


--
-- Name: COLUMN system_oauth2_client.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.status IS '状态';


--
-- Name: COLUMN system_oauth2_client.access_token_validity_seconds; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.access_token_validity_seconds IS '访问令牌的有效期';


--
-- Name: COLUMN system_oauth2_client.refresh_token_validity_seconds; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.refresh_token_validity_seconds IS '刷新令牌的有效期';


--
-- Name: COLUMN system_oauth2_client.redirect_uris; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.redirect_uris IS '可重定向的 URI 地址';


--
-- Name: COLUMN system_oauth2_client.authorized_grant_types; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.authorized_grant_types IS '授权类型';


--
-- Name: COLUMN system_oauth2_client.scopes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.scopes IS '授权范围';


--
-- Name: COLUMN system_oauth2_client.auto_approve_scopes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.auto_approve_scopes IS '自动通过的授权范围';


--
-- Name: COLUMN system_oauth2_client.authorities; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.authorities IS '权限';


--
-- Name: COLUMN system_oauth2_client.resource_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.resource_ids IS '资源';


--
-- Name: COLUMN system_oauth2_client.additional_information; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.additional_information IS '附加信息';


--
-- Name: COLUMN system_oauth2_client.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.creator IS '创建者';


--
-- Name: COLUMN system_oauth2_client.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.create_time IS '创建时间';


--
-- Name: COLUMN system_oauth2_client.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.updater IS '更新者';


--
-- Name: COLUMN system_oauth2_client.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.update_time IS '更新时间';


--
-- Name: COLUMN system_oauth2_client.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_client.deleted IS '是否删除';


--
-- Name: system_oauth2_client_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_oauth2_client_seq
    START WITH 43
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_oauth2_code; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_oauth2_code (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    user_type smallint NOT NULL,
    code character varying(32) NOT NULL,
    client_id character varying(255) NOT NULL,
    scopes character varying(255) DEFAULT ''::character varying,
    expires_time timestamp without time zone NOT NULL,
    redirect_uri character varying(255) DEFAULT NULL::character varying,
    state character varying(255) DEFAULT ''::character varying NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_oauth2_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_oauth2_code IS 'OAuth2 授权码表';


--
-- Name: COLUMN system_oauth2_code.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.id IS '编号';


--
-- Name: COLUMN system_oauth2_code.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.user_id IS '用户编号';


--
-- Name: COLUMN system_oauth2_code.user_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.user_type IS '用户类型';


--
-- Name: COLUMN system_oauth2_code.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.code IS '授权码';


--
-- Name: COLUMN system_oauth2_code.client_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.client_id IS '客户端编号';


--
-- Name: COLUMN system_oauth2_code.scopes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.scopes IS '授权范围';


--
-- Name: COLUMN system_oauth2_code.expires_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.expires_time IS '过期时间';


--
-- Name: COLUMN system_oauth2_code.redirect_uri; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.redirect_uri IS '可重定向的 URI 地址';


--
-- Name: COLUMN system_oauth2_code.state; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.state IS '状态';


--
-- Name: COLUMN system_oauth2_code.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.creator IS '创建者';


--
-- Name: COLUMN system_oauth2_code.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.create_time IS '创建时间';


--
-- Name: COLUMN system_oauth2_code.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.updater IS '更新者';


--
-- Name: COLUMN system_oauth2_code.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.update_time IS '更新时间';


--
-- Name: COLUMN system_oauth2_code.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.deleted IS '是否删除';


--
-- Name: COLUMN system_oauth2_code.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_code.tenant_id IS '租户编号';


--
-- Name: system_oauth2_code_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_oauth2_code_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_oauth2_refresh_token; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_oauth2_refresh_token (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    refresh_token character varying(32) NOT NULL,
    user_type smallint NOT NULL,
    client_id character varying(255) NOT NULL,
    scopes character varying(255) DEFAULT NULL::character varying,
    expires_time timestamp without time zone NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_oauth2_refresh_token; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_oauth2_refresh_token IS 'OAuth2 刷新令牌';


--
-- Name: COLUMN system_oauth2_refresh_token.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_refresh_token.id IS '编号';


--
-- Name: COLUMN system_oauth2_refresh_token.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_refresh_token.user_id IS '用户编号';


--
-- Name: COLUMN system_oauth2_refresh_token.refresh_token; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_refresh_token.refresh_token IS '刷新令牌';


--
-- Name: COLUMN system_oauth2_refresh_token.user_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_refresh_token.user_type IS '用户类型';


--
-- Name: COLUMN system_oauth2_refresh_token.client_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_refresh_token.client_id IS '客户端编号';


--
-- Name: COLUMN system_oauth2_refresh_token.scopes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_refresh_token.scopes IS '授权范围';


--
-- Name: COLUMN system_oauth2_refresh_token.expires_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_refresh_token.expires_time IS '过期时间';


--
-- Name: COLUMN system_oauth2_refresh_token.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_refresh_token.creator IS '创建者';


--
-- Name: COLUMN system_oauth2_refresh_token.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_refresh_token.create_time IS '创建时间';


--
-- Name: COLUMN system_oauth2_refresh_token.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_refresh_token.updater IS '更新者';


--
-- Name: COLUMN system_oauth2_refresh_token.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_refresh_token.update_time IS '更新时间';


--
-- Name: COLUMN system_oauth2_refresh_token.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_refresh_token.deleted IS '是否删除';


--
-- Name: COLUMN system_oauth2_refresh_token.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_oauth2_refresh_token.tenant_id IS '租户编号';


--
-- Name: system_oauth2_refresh_token_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_oauth2_refresh_token_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_operate_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_operate_log (
    id bigint NOT NULL,
    trace_id character varying(64) DEFAULT ''::character varying NOT NULL,
    user_id bigint NOT NULL,
    user_type smallint DEFAULT 0 NOT NULL,
    type character varying(50) NOT NULL,
    sub_type character varying(50) NOT NULL,
    biz_id bigint NOT NULL,
    action character varying(2000) DEFAULT ''::character varying NOT NULL,
    success boolean DEFAULT true NOT NULL,
    extra character varying(2000) DEFAULT ''::character varying NOT NULL,
    request_method character varying(16) DEFAULT ''::character varying,
    request_url character varying(255) DEFAULT ''::character varying,
    user_ip character varying(50) DEFAULT NULL::character varying,
    user_agent character varying(512) DEFAULT NULL::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_operate_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_operate_log IS '操作日志记录 V2 版本';


--
-- Name: COLUMN system_operate_log.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.id IS '日志主键';


--
-- Name: COLUMN system_operate_log.trace_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.trace_id IS '链路追踪编号';


--
-- Name: COLUMN system_operate_log.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.user_id IS '用户编号';


--
-- Name: COLUMN system_operate_log.user_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.user_type IS '用户类型';


--
-- Name: COLUMN system_operate_log.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.type IS '操作模块类型';


--
-- Name: COLUMN system_operate_log.sub_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.sub_type IS '操作名';


--
-- Name: COLUMN system_operate_log.biz_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.biz_id IS '操作数据模块编号';


--
-- Name: COLUMN system_operate_log.action; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.action IS '操作内容';


--
-- Name: COLUMN system_operate_log.success; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.success IS '操作结果';


--
-- Name: COLUMN system_operate_log.extra; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.extra IS '拓展字段';


--
-- Name: COLUMN system_operate_log.request_method; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.request_method IS '请求方法名';


--
-- Name: COLUMN system_operate_log.request_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.request_url IS '请求地址';


--
-- Name: COLUMN system_operate_log.user_ip; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.user_ip IS '用户 IP';


--
-- Name: COLUMN system_operate_log.user_agent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.user_agent IS '浏览器 UA';


--
-- Name: COLUMN system_operate_log.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.creator IS '创建者';


--
-- Name: COLUMN system_operate_log.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.create_time IS '创建时间';


--
-- Name: COLUMN system_operate_log.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.updater IS '更新者';


--
-- Name: COLUMN system_operate_log.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.update_time IS '更新时间';


--
-- Name: COLUMN system_operate_log.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.deleted IS '是否删除';


--
-- Name: COLUMN system_operate_log.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_operate_log.tenant_id IS '租户编号';


--
-- Name: system_operate_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_operate_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_post; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_post (
    id bigint NOT NULL,
    code character varying(64) NOT NULL,
    name character varying(50) NOT NULL,
    sort integer NOT NULL,
    status smallint NOT NULL,
    remark character varying(500) DEFAULT NULL::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_post; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_post IS '岗位信息表';


--
-- Name: COLUMN system_post.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_post.id IS '岗位ID';


--
-- Name: COLUMN system_post.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_post.code IS '岗位编码';


--
-- Name: COLUMN system_post.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_post.name IS '岗位名称';


--
-- Name: COLUMN system_post.sort; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_post.sort IS '显示顺序';


--
-- Name: COLUMN system_post.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_post.status IS '状态（0正常 1停用）';


--
-- Name: COLUMN system_post.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_post.remark IS '备注';


--
-- Name: COLUMN system_post.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_post.creator IS '创建者';


--
-- Name: COLUMN system_post.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_post.create_time IS '创建时间';


--
-- Name: COLUMN system_post.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_post.updater IS '更新者';


--
-- Name: COLUMN system_post.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_post.update_time IS '更新时间';


--
-- Name: COLUMN system_post.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_post.deleted IS '是否删除';


--
-- Name: COLUMN system_post.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_post.tenant_id IS '租户编号';


--
-- Name: system_post_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_post_seq
    START WITH 8
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_role (
    id bigint NOT NULL,
    name character varying(30) NOT NULL,
    code character varying(100) NOT NULL,
    sort integer NOT NULL,
    data_scope smallint DEFAULT 1 NOT NULL,
    data_scope_dept_ids character varying(500) DEFAULT ''::character varying NOT NULL,
    status smallint NOT NULL,
    type smallint NOT NULL,
    remark character varying(500) DEFAULT NULL::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_role; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_role IS '角色信息表';


--
-- Name: COLUMN system_role.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.id IS '角色ID';


--
-- Name: COLUMN system_role.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.name IS '角色名称';


--
-- Name: COLUMN system_role.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.code IS '角色权限字符串';


--
-- Name: COLUMN system_role.sort; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.sort IS '显示顺序';


--
-- Name: COLUMN system_role.data_scope; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.data_scope IS '数据范围（1：全部数据权限 2：自定数据权限 3：本部门数据权限 4：本部门及以下数据权限）';


--
-- Name: COLUMN system_role.data_scope_dept_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.data_scope_dept_ids IS '数据范围(指定部门数组)';


--
-- Name: COLUMN system_role.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.status IS '角色状态（0正常 1停用）';


--
-- Name: COLUMN system_role.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.type IS '角色类型';


--
-- Name: COLUMN system_role.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.remark IS '备注';


--
-- Name: COLUMN system_role.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.creator IS '创建者';


--
-- Name: COLUMN system_role.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.create_time IS '创建时间';


--
-- Name: COLUMN system_role.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.updater IS '更新者';


--
-- Name: COLUMN system_role.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.update_time IS '更新时间';


--
-- Name: COLUMN system_role.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.deleted IS '是否删除';


--
-- Name: COLUMN system_role.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role.tenant_id IS '租户编号';


--
-- Name: system_role_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_role_menu (
    id bigint NOT NULL,
    role_id bigint NOT NULL,
    menu_id bigint NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_role_menu; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_role_menu IS '角色和菜单关联表';


--
-- Name: COLUMN system_role_menu.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role_menu.id IS '自增编号';


--
-- Name: COLUMN system_role_menu.role_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role_menu.role_id IS '角色ID';


--
-- Name: COLUMN system_role_menu.menu_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role_menu.menu_id IS '菜单ID';


--
-- Name: COLUMN system_role_menu.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role_menu.creator IS '创建者';


--
-- Name: COLUMN system_role_menu.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role_menu.create_time IS '创建时间';


--
-- Name: COLUMN system_role_menu.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role_menu.updater IS '更新者';


--
-- Name: COLUMN system_role_menu.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role_menu.update_time IS '更新时间';


--
-- Name: COLUMN system_role_menu.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role_menu.deleted IS '是否删除';


--
-- Name: COLUMN system_role_menu.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_role_menu.tenant_id IS '租户编号';


--
-- Name: system_role_menu_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_role_menu_seq
    START WITH 6365
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_role_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_role_seq
    START WITH 156
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_sms_channel; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_sms_channel (
    id bigint NOT NULL,
    signature character varying(12) NOT NULL,
    code character varying(63) NOT NULL,
    status smallint NOT NULL,
    remark character varying(255) DEFAULT NULL::character varying,
    api_key character varying(128) NOT NULL,
    api_secret character varying(128) DEFAULT NULL::character varying,
    callback_url character varying(255) DEFAULT NULL::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_sms_channel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_sms_channel IS '短信渠道';


--
-- Name: COLUMN system_sms_channel.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_channel.id IS '编号';


--
-- Name: COLUMN system_sms_channel.signature; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_channel.signature IS '短信签名';


--
-- Name: COLUMN system_sms_channel.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_channel.code IS '渠道编码';


--
-- Name: COLUMN system_sms_channel.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_channel.status IS '开启状态';


--
-- Name: COLUMN system_sms_channel.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_channel.remark IS '备注';


--
-- Name: COLUMN system_sms_channel.api_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_channel.api_key IS '短信 API 的账号';


--
-- Name: COLUMN system_sms_channel.api_secret; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_channel.api_secret IS '短信 API 的秘钥';


--
-- Name: COLUMN system_sms_channel.callback_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_channel.callback_url IS '短信发送回调 URL';


--
-- Name: COLUMN system_sms_channel.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_channel.creator IS '创建者';


--
-- Name: COLUMN system_sms_channel.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_channel.create_time IS '创建时间';


--
-- Name: COLUMN system_sms_channel.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_channel.updater IS '更新者';


--
-- Name: COLUMN system_sms_channel.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_channel.update_time IS '更新时间';


--
-- Name: COLUMN system_sms_channel.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_channel.deleted IS '是否删除';


--
-- Name: system_sms_channel_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_sms_channel_seq
    START WITH 8
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_sms_code; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_sms_code (
    id bigint NOT NULL,
    mobile character varying(11) NOT NULL,
    code character varying(6) NOT NULL,
    create_ip character varying(15) NOT NULL,
    scene smallint NOT NULL,
    today_index smallint NOT NULL,
    used smallint NOT NULL,
    used_time timestamp without time zone,
    used_ip character varying(255) DEFAULT NULL::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_sms_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_sms_code IS '手机验证码';


--
-- Name: COLUMN system_sms_code.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.id IS '编号';


--
-- Name: COLUMN system_sms_code.mobile; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.mobile IS '手机号';


--
-- Name: COLUMN system_sms_code.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.code IS '验证码';


--
-- Name: COLUMN system_sms_code.create_ip; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.create_ip IS '创建 IP';


--
-- Name: COLUMN system_sms_code.scene; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.scene IS '发送场景';


--
-- Name: COLUMN system_sms_code.today_index; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.today_index IS '今日发送的第几条';


--
-- Name: COLUMN system_sms_code.used; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.used IS '是否使用';


--
-- Name: COLUMN system_sms_code.used_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.used_time IS '使用时间';


--
-- Name: COLUMN system_sms_code.used_ip; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.used_ip IS '使用 IP';


--
-- Name: COLUMN system_sms_code.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.creator IS '创建者';


--
-- Name: COLUMN system_sms_code.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.create_time IS '创建时间';


--
-- Name: COLUMN system_sms_code.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.updater IS '更新者';


--
-- Name: COLUMN system_sms_code.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.update_time IS '更新时间';


--
-- Name: COLUMN system_sms_code.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.deleted IS '是否删除';


--
-- Name: COLUMN system_sms_code.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_code.tenant_id IS '租户编号';


--
-- Name: system_sms_code_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_sms_code_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_sms_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_sms_log (
    id bigint NOT NULL,
    channel_id bigint NOT NULL,
    channel_code character varying(63) NOT NULL,
    template_id bigint NOT NULL,
    template_code character varying(63) NOT NULL,
    template_type smallint NOT NULL,
    template_content character varying(255) NOT NULL,
    template_params character varying(255) NOT NULL,
    api_template_id character varying(63) NOT NULL,
    mobile character varying(11) NOT NULL,
    user_id bigint,
    user_type smallint,
    send_status smallint DEFAULT 0 NOT NULL,
    send_time timestamp without time zone,
    api_send_code character varying(63) DEFAULT NULL::character varying,
    api_send_msg character varying(255) DEFAULT NULL::character varying,
    api_request_id character varying(255) DEFAULT NULL::character varying,
    api_serial_no character varying(255) DEFAULT NULL::character varying,
    receive_status smallint DEFAULT 0 NOT NULL,
    receive_time timestamp without time zone,
    api_receive_code character varying(63) DEFAULT NULL::character varying,
    api_receive_msg character varying(255) DEFAULT NULL::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_sms_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_sms_log IS '短信日志';


--
-- Name: COLUMN system_sms_log.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.id IS '编号';


--
-- Name: COLUMN system_sms_log.channel_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.channel_id IS '短信渠道编号';


--
-- Name: COLUMN system_sms_log.channel_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.channel_code IS '短信渠道编码';


--
-- Name: COLUMN system_sms_log.template_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.template_id IS '模板编号';


--
-- Name: COLUMN system_sms_log.template_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.template_code IS '模板编码';


--
-- Name: COLUMN system_sms_log.template_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.template_type IS '短信类型';


--
-- Name: COLUMN system_sms_log.template_content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.template_content IS '短信内容';


--
-- Name: COLUMN system_sms_log.template_params; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.template_params IS '短信参数';


--
-- Name: COLUMN system_sms_log.api_template_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.api_template_id IS '短信 API 的模板编号';


--
-- Name: COLUMN system_sms_log.mobile; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.mobile IS '手机号';


--
-- Name: COLUMN system_sms_log.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.user_id IS '用户编号';


--
-- Name: COLUMN system_sms_log.user_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.user_type IS '用户类型';


--
-- Name: COLUMN system_sms_log.send_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.send_status IS '发送状态';


--
-- Name: COLUMN system_sms_log.send_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.send_time IS '发送时间';


--
-- Name: COLUMN system_sms_log.api_send_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.api_send_code IS '短信 API 发送结果的编码';


--
-- Name: COLUMN system_sms_log.api_send_msg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.api_send_msg IS '短信 API 发送失败的提示';


--
-- Name: COLUMN system_sms_log.api_request_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.api_request_id IS '短信 API 发送返回的唯一请求 ID';


--
-- Name: COLUMN system_sms_log.api_serial_no; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.api_serial_no IS '短信 API 发送返回的序号';


--
-- Name: COLUMN system_sms_log.receive_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.receive_status IS '接收状态';


--
-- Name: COLUMN system_sms_log.receive_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.receive_time IS '接收时间';


--
-- Name: COLUMN system_sms_log.api_receive_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.api_receive_code IS 'API 接收结果的编码';


--
-- Name: COLUMN system_sms_log.api_receive_msg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.api_receive_msg IS 'API 接收结果的说明';


--
-- Name: COLUMN system_sms_log.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.creator IS '创建者';


--
-- Name: COLUMN system_sms_log.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.create_time IS '创建时间';


--
-- Name: COLUMN system_sms_log.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.updater IS '更新者';


--
-- Name: COLUMN system_sms_log.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.update_time IS '更新时间';


--
-- Name: COLUMN system_sms_log.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_log.deleted IS '是否删除';


--
-- Name: system_sms_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_sms_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_sms_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_sms_template (
    id bigint NOT NULL,
    type smallint NOT NULL,
    status smallint NOT NULL,
    code character varying(63) NOT NULL,
    name character varying(63) NOT NULL,
    content character varying(255) NOT NULL,
    params character varying(255) NOT NULL,
    remark character varying(255) DEFAULT NULL::character varying,
    api_template_id character varying(63) NOT NULL,
    channel_id bigint NOT NULL,
    channel_code character varying(63) NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_sms_template; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_sms_template IS '短信模板';


--
-- Name: COLUMN system_sms_template.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.id IS '编号';


--
-- Name: COLUMN system_sms_template.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.type IS '模板类型';


--
-- Name: COLUMN system_sms_template.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.status IS '开启状态';


--
-- Name: COLUMN system_sms_template.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.code IS '模板编码';


--
-- Name: COLUMN system_sms_template.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.name IS '模板名称';


--
-- Name: COLUMN system_sms_template.content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.content IS '模板内容';


--
-- Name: COLUMN system_sms_template.params; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.params IS '参数数组';


--
-- Name: COLUMN system_sms_template.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.remark IS '备注';


--
-- Name: COLUMN system_sms_template.api_template_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.api_template_id IS '短信 API 的模板编号';


--
-- Name: COLUMN system_sms_template.channel_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.channel_id IS '短信渠道编号';


--
-- Name: COLUMN system_sms_template.channel_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.channel_code IS '短信渠道编码';


--
-- Name: COLUMN system_sms_template.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.creator IS '创建者';


--
-- Name: COLUMN system_sms_template.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.create_time IS '创建时间';


--
-- Name: COLUMN system_sms_template.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.updater IS '更新者';


--
-- Name: COLUMN system_sms_template.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.update_time IS '更新时间';


--
-- Name: COLUMN system_sms_template.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_sms_template.deleted IS '是否删除';


--
-- Name: system_sms_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_sms_template_seq
    START WITH 20
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_social_client; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_social_client (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    social_type smallint NOT NULL,
    user_type smallint NOT NULL,
    client_id character varying(255) NOT NULL,
    client_secret character varying(255) NOT NULL,
    agent_id character varying(255) DEFAULT NULL::character varying,
    public_key character varying(2048) DEFAULT NULL::character varying,
    status smallint NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_social_client; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_social_client IS '社交客户端表';


--
-- Name: COLUMN system_social_client.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.id IS '编号';


--
-- Name: COLUMN system_social_client.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.name IS '应用名';


--
-- Name: COLUMN system_social_client.social_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.social_type IS '社交平台的类型';


--
-- Name: COLUMN system_social_client.user_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.user_type IS '用户类型';


--
-- Name: COLUMN system_social_client.client_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.client_id IS '客户端编号';


--
-- Name: COLUMN system_social_client.client_secret; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.client_secret IS '客户端密钥';


--
-- Name: COLUMN system_social_client.agent_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.agent_id IS '代理编号';


--
-- Name: COLUMN system_social_client.public_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.public_key IS 'publicKey 公钥';


--
-- Name: COLUMN system_social_client.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.status IS '状态';


--
-- Name: COLUMN system_social_client.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.creator IS '创建者';


--
-- Name: COLUMN system_social_client.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.create_time IS '创建时间';


--
-- Name: COLUMN system_social_client.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.updater IS '更新者';


--
-- Name: COLUMN system_social_client.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.update_time IS '更新时间';


--
-- Name: COLUMN system_social_client.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.deleted IS '是否删除';


--
-- Name: COLUMN system_social_client.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_client.tenant_id IS '租户编号';


--
-- Name: system_social_client_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_social_client_seq
    START WITH 48
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_social_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_social_user (
    id bigint NOT NULL,
    type smallint NOT NULL,
    openid character varying(32) NOT NULL,
    token character varying(256) DEFAULT NULL::character varying,
    raw_token_info character varying(1024) NOT NULL,
    nickname character varying(32) NOT NULL,
    avatar character varying(255) DEFAULT NULL::character varying,
    raw_user_info character varying(1024) NOT NULL,
    code character varying(256) NOT NULL,
    state character varying(256) DEFAULT NULL::character varying,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_social_user; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_social_user IS '社交用户表';


--
-- Name: COLUMN system_social_user.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.id IS '主键(自增策略)';


--
-- Name: COLUMN system_social_user.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.type IS '社交平台的类型';


--
-- Name: COLUMN system_social_user.openid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.openid IS '社交 openid';


--
-- Name: COLUMN system_social_user.token; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.token IS '社交 token';


--
-- Name: COLUMN system_social_user.raw_token_info; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.raw_token_info IS '原始 Token 数据，一般是 JSON 格式';


--
-- Name: COLUMN system_social_user.nickname; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.nickname IS '用户昵称';


--
-- Name: COLUMN system_social_user.avatar; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.avatar IS '用户头像';


--
-- Name: COLUMN system_social_user.raw_user_info; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.raw_user_info IS '原始用户数据，一般是 JSON 格式';


--
-- Name: COLUMN system_social_user.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.code IS '最后一次的认证 code';


--
-- Name: COLUMN system_social_user.state; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.state IS '最后一次的认证 state';


--
-- Name: COLUMN system_social_user.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.creator IS '创建者';


--
-- Name: COLUMN system_social_user.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.create_time IS '创建时间';


--
-- Name: COLUMN system_social_user.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.updater IS '更新者';


--
-- Name: COLUMN system_social_user.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.update_time IS '更新时间';


--
-- Name: COLUMN system_social_user.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.deleted IS '是否删除';


--
-- Name: COLUMN system_social_user.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user.tenant_id IS '租户编号';


--
-- Name: system_social_user_bind; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_social_user_bind (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    user_type smallint NOT NULL,
    social_type smallint NOT NULL,
    social_user_id bigint NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_social_user_bind; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_social_user_bind IS '社交绑定表';


--
-- Name: COLUMN system_social_user_bind.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user_bind.id IS '主键(自增策略)';


--
-- Name: COLUMN system_social_user_bind.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user_bind.user_id IS '用户编号';


--
-- Name: COLUMN system_social_user_bind.user_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user_bind.user_type IS '用户类型';


--
-- Name: COLUMN system_social_user_bind.social_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user_bind.social_type IS '社交平台的类型';


--
-- Name: COLUMN system_social_user_bind.social_user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user_bind.social_user_id IS '社交用户的编号';


--
-- Name: COLUMN system_social_user_bind.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user_bind.creator IS '创建者';


--
-- Name: COLUMN system_social_user_bind.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user_bind.create_time IS '创建时间';


--
-- Name: COLUMN system_social_user_bind.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user_bind.updater IS '更新者';


--
-- Name: COLUMN system_social_user_bind.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user_bind.update_time IS '更新时间';


--
-- Name: COLUMN system_social_user_bind.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user_bind.deleted IS '是否删除';


--
-- Name: COLUMN system_social_user_bind.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_social_user_bind.tenant_id IS '租户编号';


--
-- Name: system_social_user_bind_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_social_user_bind_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_social_user_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_social_user_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_tenant; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_tenant (
    id bigint NOT NULL,
    name character varying(30) NOT NULL,
    contact_user_id bigint,
    contact_name character varying(30) NOT NULL,
    contact_mobile character varying(500) DEFAULT NULL::character varying,
    status smallint DEFAULT 0 NOT NULL,
    websites character varying(1024) DEFAULT ''::character varying,
    package_id bigint NOT NULL,
    expire_time timestamp without time zone NOT NULL,
    account_count integer NOT NULL,
    creator character varying(64) DEFAULT ''::character varying NOT NULL,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_tenant; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_tenant IS '租户表';


--
-- Name: COLUMN system_tenant.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.id IS '租户编号';


--
-- Name: COLUMN system_tenant.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.name IS '租户名';


--
-- Name: COLUMN system_tenant.contact_user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.contact_user_id IS '联系人的用户编号';


--
-- Name: COLUMN system_tenant.contact_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.contact_name IS '联系人';


--
-- Name: COLUMN system_tenant.contact_mobile; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.contact_mobile IS '联系手机';


--
-- Name: COLUMN system_tenant.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.status IS '租户状态';


--
-- Name: COLUMN system_tenant.websites; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.websites IS '绑定域名数组';


--
-- Name: COLUMN system_tenant.package_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.package_id IS '租户套餐编号';


--
-- Name: COLUMN system_tenant.expire_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.expire_time IS '过期时间';


--
-- Name: COLUMN system_tenant.account_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.account_count IS '账号数量';


--
-- Name: COLUMN system_tenant.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.creator IS '创建者';


--
-- Name: COLUMN system_tenant.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.create_time IS '创建时间';


--
-- Name: COLUMN system_tenant.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.updater IS '更新者';


--
-- Name: COLUMN system_tenant.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.update_time IS '更新时间';


--
-- Name: COLUMN system_tenant.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant.deleted IS '是否删除';


--
-- Name: system_tenant_package; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_tenant_package (
    id bigint NOT NULL,
    name character varying(30) NOT NULL,
    status smallint DEFAULT 0 NOT NULL,
    remark character varying(256) DEFAULT ''::character varying,
    menu_ids character varying(4096) NOT NULL,
    creator character varying(64) DEFAULT ''::character varying NOT NULL,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_tenant_package; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_tenant_package IS '租户套餐表';


--
-- Name: COLUMN system_tenant_package.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant_package.id IS '套餐编号';


--
-- Name: COLUMN system_tenant_package.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant_package.name IS '套餐名';


--
-- Name: COLUMN system_tenant_package.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant_package.status IS '租户状态（0正常 1停用）';


--
-- Name: COLUMN system_tenant_package.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant_package.remark IS '备注';


--
-- Name: COLUMN system_tenant_package.menu_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant_package.menu_ids IS '关联的菜单编号';


--
-- Name: COLUMN system_tenant_package.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant_package.creator IS '创建者';


--
-- Name: COLUMN system_tenant_package.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant_package.create_time IS '创建时间';


--
-- Name: COLUMN system_tenant_package.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant_package.updater IS '更新者';


--
-- Name: COLUMN system_tenant_package.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant_package.update_time IS '更新时间';


--
-- Name: COLUMN system_tenant_package.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_tenant_package.deleted IS '是否删除';


--
-- Name: system_tenant_package_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_tenant_package_seq
    START WITH 112
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_tenant_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_tenant_seq
    START WITH 123
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_user_post; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_user_post (
    id bigint NOT NULL,
    user_id bigint DEFAULT 0 NOT NULL,
    post_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_user_post; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_user_post IS '用户岗位表';


--
-- Name: COLUMN system_user_post.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_post.id IS 'id';


--
-- Name: COLUMN system_user_post.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_post.user_id IS '用户ID';


--
-- Name: COLUMN system_user_post.post_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_post.post_id IS '岗位ID';


--
-- Name: COLUMN system_user_post.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_post.creator IS '创建者';


--
-- Name: COLUMN system_user_post.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_post.create_time IS '创建时间';


--
-- Name: COLUMN system_user_post.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_post.updater IS '更新者';


--
-- Name: COLUMN system_user_post.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_post.update_time IS '更新时间';


--
-- Name: COLUMN system_user_post.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_post.deleted IS '是否删除';


--
-- Name: COLUMN system_user_post.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_post.tenant_id IS '租户编号';


--
-- Name: system_user_post_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_user_post_seq
    START WITH 130
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_user_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_user_role (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    role_id bigint NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_user_role; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_user_role IS '用户和角色关联表';


--
-- Name: COLUMN system_user_role.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_role.id IS '自增编号';


--
-- Name: COLUMN system_user_role.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_role.user_id IS '用户ID';


--
-- Name: COLUMN system_user_role.role_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_role.role_id IS '角色ID';


--
-- Name: COLUMN system_user_role.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_role.creator IS '创建者';


--
-- Name: COLUMN system_user_role.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_role.create_time IS '创建时间';


--
-- Name: COLUMN system_user_role.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_role.updater IS '更新者';


--
-- Name: COLUMN system_user_role.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_role.update_time IS '更新时间';


--
-- Name: COLUMN system_user_role.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_role.deleted IS '是否删除';


--
-- Name: COLUMN system_user_role.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_user_role.tenant_id IS '租户编号';


--
-- Name: system_user_role_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_user_role_seq
    START WITH 55
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_users (
    id bigint NOT NULL,
    username character varying(30) NOT NULL,
    password character varying(100) DEFAULT ''::character varying NOT NULL,
    nickname character varying(30) NOT NULL,
    remark character varying(500) DEFAULT NULL::character varying,
    dept_id bigint,
    post_ids character varying(255) DEFAULT NULL::character varying,
    email character varying(50) DEFAULT ''::character varying,
    mobile character varying(11) DEFAULT ''::character varying,
    sex smallint DEFAULT 0,
    avatar character varying(512) DEFAULT ''::character varying,
    status smallint DEFAULT 0 NOT NULL,
    login_ip character varying(50) DEFAULT ''::character varying,
    login_date timestamp without time zone,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE system_users; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_users IS '用户信息表';


--
-- Name: COLUMN system_users.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.id IS '用户ID';


--
-- Name: COLUMN system_users.username; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.username IS '用户账号';


--
-- Name: COLUMN system_users.password; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.password IS '密码';


--
-- Name: COLUMN system_users.nickname; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.nickname IS '用户昵称';


--
-- Name: COLUMN system_users.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.remark IS '备注';


--
-- Name: COLUMN system_users.dept_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.dept_id IS '部门ID';


--
-- Name: COLUMN system_users.post_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.post_ids IS '岗位编号数组';


--
-- Name: COLUMN system_users.email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.email IS '用户邮箱';


--
-- Name: COLUMN system_users.mobile; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.mobile IS '手机号码';


--
-- Name: COLUMN system_users.sex; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.sex IS '用户性别';


--
-- Name: COLUMN system_users.avatar; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.avatar IS '头像地址';


--
-- Name: COLUMN system_users.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.status IS '帐号状态（0正常 1停用）';


--
-- Name: COLUMN system_users.login_ip; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.login_ip IS '最后登录IP';


--
-- Name: COLUMN system_users.login_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.login_date IS '最后登录时间';


--
-- Name: COLUMN system_users.creator; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.creator IS '创建者';


--
-- Name: COLUMN system_users.create_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.create_time IS '创建时间';


--
-- Name: COLUMN system_users.updater; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.updater IS '更新者';


--
-- Name: COLUMN system_users.update_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.update_time IS '更新时间';


--
-- Name: COLUMN system_users.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.deleted IS '是否删除';


--
-- Name: COLUMN system_users.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_users.tenant_id IS '租户编号';


--
-- Name: system_users_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_users_seq
    START WITH 145
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_after_sale; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_after_sale (
    id bigint NOT NULL,
    no text,
    status integer,
    way integer,
    type integer,
    user_id bigint,
    apply_reason text,
    apply_description text,
    apply_pic_urls text,
    order_id bigint,
    order_no text,
    order_item_id bigint,
    spu_id bigint,
    spu_name text,
    sku_id bigint,
    properties text,
    pic_url text,
    count integer,
    audit_time timestamp without time zone,
    audit_user_id bigint,
    audit_reason text,
    refund_price integer,
    pay_refund_id bigint,
    refund_time timestamp without time zone,
    logistics_id bigint,
    logistics_no text,
    delivery_time timestamp without time zone,
    receive_time timestamp without time zone,
    receive_reason text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    refund_channel_code character varying(32),
    refund_proof_urls text,
    refund_remark character varying(255)
);


--
-- Name: COLUMN trade_after_sale.refund_channel_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_after_sale.refund_channel_code IS '线下退款渠道（字典 pay_channel_code 的线下值）';


--
-- Name: COLUMN trade_after_sale.refund_proof_urls; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_after_sale.refund_proof_urls IS '线下退款凭证图片（JSON 数组）';


--
-- Name: COLUMN trade_after_sale.refund_remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_after_sale.refund_remark IS '线下退款备注';


--
-- Name: trade_after_sale_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_after_sale_log (
    id bigint NOT NULL,
    user_id bigint,
    user_type integer,
    after_sale_id bigint,
    before_status integer,
    after_status integer,
    operate_type integer,
    content text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: trade_after_sale_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_after_sale_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_after_sale_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_after_sale_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_brokerage_record_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_brokerage_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_brokerage_user_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_brokerage_user_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_brokerage_withdraw_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_brokerage_withdraw_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_cart; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_cart (
    id bigint NOT NULL,
    user_id bigint,
    spu_id bigint,
    sku_id bigint,
    count integer,
    selected boolean,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: trade_cart_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_cart_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_config (
    id bigint NOT NULL,
    after_sale_refund_reasons text,
    after_sale_return_reasons text,
    delivery_express_free_enabled boolean,
    delivery_express_free_price integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: trade_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_delivery_express; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_delivery_express (
    id bigint NOT NULL,
    code text,
    name text,
    logo text,
    sort integer,
    status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: trade_delivery_express_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_delivery_express_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_delivery_express_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_delivery_express_template (
    id bigint NOT NULL,
    name text,
    charge_mode integer,
    sort integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: trade_delivery_express_template_charge; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_delivery_express_template_charge (
    id bigint NOT NULL,
    template_id bigint,
    area_ids text,
    charge_mode integer,
    start_count double precision,
    start_price integer,
    extra_count double precision,
    extra_price integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: trade_delivery_express_template_charge_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_delivery_express_template_charge_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_delivery_express_template_free; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_delivery_express_template_free (
    id bigint NOT NULL,
    template_id bigint,
    area_ids text,
    free_price integer,
    free_count integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: trade_delivery_express_template_free_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_delivery_express_template_free_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_delivery_express_template_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_delivery_express_template_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_delivery_pick_up_store_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_delivery_pick_up_store_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_order (
    id bigint NOT NULL,
    no text,
    type integer,
    terminal integer,
    user_id bigint,
    user_ip text,
    user_remark text,
    status integer,
    product_count integer,
    finish_time timestamp without time zone,
    cancel_time timestamp without time zone,
    cancel_type integer,
    remark text,
    pay_order_id bigint,
    pay_status boolean,
    pay_time timestamp without time zone,
    pay_channel_code text,
    total_price integer,
    discount_price integer,
    delivery_price integer,
    adjust_price integer DEFAULT 0,
    pay_price integer,
    delivery_type integer,
    logistics_id bigint,
    logistics_no text,
    delivery_time timestamp without time zone,
    receive_time timestamp without time zone,
    receiver_name text,
    receiver_mobile text,
    receiver_area_id integer,
    receiver_detail_address text,
    refund_status integer,
    refund_price integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    paid_amount integer DEFAULT 0 NOT NULL,
    payment_proof_status smallint DEFAULT 0 NOT NULL,
    dept_id bigint,
    customer_id bigint,
    settlement_mode character varying(20),
    audit_status smallint DEFAULT 0 NOT NULL,
    audit_user_id bigint,
    audit_time timestamp without time zone,
    audit_remark character varying(500) DEFAULT ''::character varying,
    process_instance_id character varying(64) DEFAULT ''::character varying,
    store_type character varying(20),
    receipt_status smallint DEFAULT 0 NOT NULL
);


--
-- Name: COLUMN trade_order.dept_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order.dept_id IS '下单门店所属部门（快照，system_dept.id）';


--
-- Name: COLUMN trade_order.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order.customer_id IS '下单门店客户编号（快照，erp_customer.id）';


--
-- Name: COLUMN trade_order.settlement_mode; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order.settlement_mode IS '结算模式快照：PREPAID 先款后货 / MONTHLY 月结';


--
-- Name: COLUMN trade_order.audit_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order.audit_status IS '审核状态：0 待提交 / 10 审核中 / 20 已通过 / 30 已驳回';


--
-- Name: COLUMN trade_order.process_instance_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order.process_instance_id IS 'BPM 审批流程实例编号';


--
-- Name: COLUMN trade_order.store_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order.store_type IS '下单门店店型快照：DIRECT 直营（免审）/ FRANCHISE 加盟（需审核）';


--
-- Name: COLUMN trade_order.receipt_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order.receipt_status IS '收货状态：0 未收货 / 10 部分收货 / 20 已收货';


--
-- Name: trade_order_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_order_item (
    id bigint NOT NULL,
    user_id bigint,
    order_id bigint,
    cart_id bigint,
    spu_id bigint,
    spu_name text,
    sku_id bigint,
    properties text,
    pic_url text,
    count integer,
    price integer,
    discount_price integer,
    delivery_price integer,
    adjust_price integer DEFAULT 0,
    pay_price integer,
    after_sale_id bigint,
    after_sale_status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    alloc_mode character varying(16),
    alloc_count numeric(24,6),
    delivered_count numeric(24,6) DEFAULT 0 NOT NULL,
    receipt_count numeric(24,6) DEFAULT 0 NOT NULL
);


--
-- Name: COLUMN trade_order_item.alloc_mode; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order_item.alloc_mode IS '分料方式：CENTRAL 统配 / DIRECT 直拨；NULL = 未分料（字典 trade_order_item_alloc_mode）';


--
-- Name: COLUMN trade_order_item.alloc_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order_item.alloc_count IS '本次分料下推数量；为空表示按整行数量下推（≤ 原数量）';


--
-- Name: COLUMN trade_order_item.delivered_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order_item.delivered_count IS 'ERP 已发货数量（配送出库单审核后回写）';


--
-- Name: COLUMN trade_order_item.receipt_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order_item.receipt_count IS '门店已确认收货数量';


--
-- Name: trade_order_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_order_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_order_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_order_log (
    id bigint NOT NULL,
    user_id bigint,
    user_type integer,
    order_id bigint,
    before_status integer,
    after_status integer,
    operate_type integer,
    content text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: trade_order_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_order_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_order_payment_proof; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_order_payment_proof (
    id bigint NOT NULL,
    order_id bigint NOT NULL,
    urls text NOT NULL,
    amount integer NOT NULL,
    confirmed_amount integer,
    payer_name character varying(64) DEFAULT ''::character varying,
    pay_channel_code character varying(32) DEFAULT ''::character varying,
    transfer_time timestamp without time zone,
    remark character varying(255) DEFAULT ''::character varying,
    status smallint DEFAULT 0 NOT NULL,
    audit_user_id bigint,
    audit_time timestamp without time zone,
    audit_remark character varying(255) DEFAULT ''::character varying,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: trade_order_payment_proof_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_order_payment_proof_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_order_receipt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_order_receipt (
    id bigint NOT NULL,
    no character varying(64) NOT NULL,
    order_id bigint NOT NULL,
    order_no character varying(64),
    customer_id bigint,
    dept_id bigint,
    member_user_id bigint,
    warehouse_id bigint,
    sale_out_id bigint,
    sale_out_no character varying(64),
    status smallint DEFAULT 0 NOT NULL,
    diff_type smallint DEFAULT 0 NOT NULL,
    total_count numeric(24,6) DEFAULT 0 NOT NULL,
    receipt_count numeric(24,6) DEFAULT 0 NOT NULL,
    diff_count numeric(24,6) DEFAULT 0 NOT NULL,
    total_price numeric(24,2) DEFAULT 0 NOT NULL,
    receipt_price numeric(24,2) DEFAULT 0 NOT NULL,
    diff_amount numeric(24,2) DEFAULT 0 NOT NULL,
    receive_time timestamp without time zone,
    receiver_name character varying(64),
    receiver_mobile character varying(32),
    file_urls text,
    remark character varying(500),
    cancel_user_id bigint,
    cancel_time timestamp without time zone,
    cancel_reason character varying(500),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT now() NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT now() NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE trade_order_receipt; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.trade_order_receipt IS '门店收货单（配送出库后由门店确认收货，含多收/少收/破损差异）';


--
-- Name: COLUMN trade_order_receipt.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order_receipt.status IS '状态：0 待确认 / 10 已确认 / 20 已作废';


--
-- Name: COLUMN trade_order_receipt.diff_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order_receipt.diff_type IS '差异类型：0 无差异 / 1 少收 / 2 多收 / 3 破损 / 4 混合';


--
-- Name: COLUMN trade_order_receipt.diff_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order_receipt.diff_count IS '差异合计（实收 − 应收，正数=多收）';


--
-- Name: trade_order_receipt_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_order_receipt_item (
    id bigint NOT NULL,
    receipt_id bigint NOT NULL,
    order_item_id bigint NOT NULL,
    spu_id bigint,
    sku_id bigint,
    spu_name character varying(255),
    properties character varying(255),
    pic_url character varying(512),
    product_id bigint,
    price numeric(24,2) DEFAULT 0 NOT NULL,
    expect_count numeric(24,6) DEFAULT 0 NOT NULL,
    receipt_count numeric(24,6) DEFAULT 0 NOT NULL,
    diff_count numeric(24,6) DEFAULT 0 NOT NULL,
    diff_amount numeric(24,2) DEFAULT 0 NOT NULL,
    diff_reason character varying(255),
    batch_no character varying(64),
    production_date date,
    expiry_date date,
    remark character varying(500),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT now() NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT now() NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE trade_order_receipt_item; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.trade_order_receipt_item IS '门店收货单明细（应收/实收/差异 + 批次效期）';


--
-- Name: COLUMN trade_order_receipt_item.price; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order_receipt_item.price IS '配送价（门店进货单位成本，用于门店库存账与差异金额）';


--
-- Name: COLUMN trade_order_receipt_item.diff_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trade_order_receipt_item.diff_count IS '差异数量（实收 − 应收，正数=多收）';


--
-- Name: trade_order_receipt_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_order_receipt_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_order_receipt_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_order_receipt_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_order_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_order_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_statistics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_statistics (
    id bigint NOT NULL,
    "time" timestamp without time zone,
    order_create_count integer,
    order_pay_count integer,
    order_pay_price integer,
    after_sale_count integer,
    after_sale_refund_price integer,
    wallet_pay_price integer,
    recharge_pay_count integer,
    recharge_pay_price integer,
    recharge_refund_count integer,
    recharge_refund_price integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: trade_statistics_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_statistics_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_check_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_check_order (
    id bigint NOT NULL,
    no text,
    order_time timestamp without time zone,
    status integer,
    remark text,
    warehouse_id bigint,
    total_quantity numeric(24,6),
    total_price numeric(24,6),
    actual_price numeric(24,6),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_check_order_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_check_order_detail (
    id bigint NOT NULL,
    order_id bigint,
    sku_id bigint,
    warehouse_id bigint,
    inventory_id bigint,
    receipt_time timestamp without time zone,
    quantity numeric(24,6),
    check_quantity numeric(24,6),
    price numeric(24,6),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_check_order_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_check_order_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_check_order_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_check_order_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_inventory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_inventory (
    id bigint NOT NULL,
    sku_id bigint,
    warehouse_id bigint,
    quantity numeric(24,6),
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_inventory_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_inventory_history (
    id bigint NOT NULL,
    warehouse_id bigint,
    sku_id bigint,
    quantity numeric(24,6),
    before_quantity numeric(24,6),
    after_quantity numeric(24,6),
    price numeric(24,6),
    total_price numeric(24,6),
    remark text,
    order_id bigint,
    order_no text,
    order_type integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_inventory_history_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_inventory_history_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_inventory_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_inventory_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_item (
    id bigint NOT NULL,
    code text,
    name text,
    unit text,
    category_id bigint,
    brand_id bigint,
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_item_brand; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_item_brand (
    id bigint NOT NULL,
    code text,
    name text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_item_brand_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_item_brand_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_item_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_item_category (
    id bigint NOT NULL,
    parent_id bigint,
    code text,
    name text,
    sort integer,
    status integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_item_category_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_item_category_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_item_sku; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_item_sku (
    id bigint NOT NULL,
    name text,
    item_id bigint,
    bar_code text,
    code text,
    length numeric(24,6),
    width numeric(24,6),
    height numeric(24,6),
    gross_weight numeric(24,6),
    net_weight numeric(24,6),
    cost_price numeric(24,6),
    selling_price numeric(24,6),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_item_sku_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_item_sku_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_merchant; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_merchant (
    id bigint NOT NULL,
    code text,
    name text,
    type integer,
    level text,
    bank_name text,
    bank_account text,
    address text,
    mobile text,
    telephone text,
    contact text,
    email text,
    remark text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_merchant_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_merchant_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_movement_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_movement_order (
    id bigint NOT NULL,
    no text,
    order_time timestamp without time zone,
    status integer,
    remark text,
    source_warehouse_id bigint,
    target_warehouse_id bigint,
    total_quantity numeric(24,6),
    total_price numeric(24,6),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_movement_order_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_movement_order_detail (
    id bigint NOT NULL,
    order_id bigint,
    sku_id bigint,
    source_warehouse_id bigint,
    target_warehouse_id bigint,
    quantity numeric(24,6),
    price numeric(24,6),
    total_price numeric(24,6),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_movement_order_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_movement_order_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_movement_order_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_movement_order_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_receipt_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_receipt_order (
    id bigint NOT NULL,
    no text,
    type integer,
    order_time timestamp without time zone,
    status integer,
    biz_order_no text,
    merchant_id bigint,
    remark text,
    warehouse_id bigint,
    total_quantity numeric(24,6),
    total_price numeric(24,6),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_receipt_order_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_receipt_order_detail (
    id bigint NOT NULL,
    order_id bigint,
    sku_id bigint,
    warehouse_id bigint,
    quantity numeric(24,6),
    price numeric(24,6),
    total_price numeric(24,6),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_receipt_order_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_receipt_order_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_receipt_order_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_receipt_order_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_shipment_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_shipment_order (
    id bigint NOT NULL,
    no text,
    type integer,
    order_time timestamp without time zone,
    status integer,
    biz_order_no text,
    merchant_id bigint,
    remark text,
    warehouse_id bigint,
    total_quantity numeric(24,6),
    total_price numeric(24,6),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_shipment_order_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_shipment_order_detail (
    id bigint NOT NULL,
    order_id bigint,
    sku_id bigint,
    warehouse_id bigint,
    quantity numeric(24,6),
    price numeric(24,6),
    total_price numeric(24,6),
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_shipment_order_detail_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_shipment_order_detail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_shipment_order_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_shipment_order_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wms_warehouse; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wms_warehouse (
    id bigint NOT NULL,
    code text,
    name text,
    remark text,
    sort integer,
    tenant_id bigint DEFAULT 0 NOT NULL,
    creator character varying(64) DEFAULT ''::character varying,
    create_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater character varying(64) DEFAULT ''::character varying,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL
);


--
-- Name: wms_warehouse_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wms_warehouse_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yudao_demo01_contact_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yudao_demo01_contact_seq
    START WITH 2
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yudao_demo02_category_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yudao_demo02_category_seq
    START WITH 8
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yudao_demo03_course_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yudao_demo03_course_seq
    START WITH 21
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yudao_demo03_grade_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yudao_demo03_grade_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yudao_demo03_student_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yudao_demo03_student_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: act_evt_log log_nr_; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_evt_log ALTER COLUMN log_nr_ SET DEFAULT nextval('public.act_evt_log_log_nr__seq'::regclass);


--
-- Name: act_hi_tsk_log id_; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_hi_tsk_log ALTER COLUMN id_ SET DEFAULT nextval('public.act_hi_tsk_log_id__seq'::regclass);


--
-- Name: flw_channel_definition FLW_CHANNEL_DEFINITION_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flw_channel_definition
    ADD CONSTRAINT "FLW_CHANNEL_DEFINITION_pkey" PRIMARY KEY (id_);


--
-- Name: flw_event_definition FLW_EVENT_DEFINITION_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flw_event_definition
    ADD CONSTRAINT "FLW_EVENT_DEFINITION_pkey" PRIMARY KEY (id_);


--
-- Name: flw_event_deployment FLW_EVENT_DEPLOYMENT_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flw_event_deployment
    ADD CONSTRAINT "FLW_EVENT_DEPLOYMENT_pkey" PRIMARY KEY (id_);


--
-- Name: flw_event_resource FLW_EVENT_RESOURCE_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flw_event_resource
    ADD CONSTRAINT "FLW_EVENT_RESOURCE_pkey" PRIMARY KEY (id_);


--
-- Name: act_evt_log act_evt_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_evt_log
    ADD CONSTRAINT act_evt_log_pkey PRIMARY KEY (log_nr_);


--
-- Name: act_ge_bytearray act_ge_bytearray_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ge_bytearray
    ADD CONSTRAINT act_ge_bytearray_pkey PRIMARY KEY (id_);


--
-- Name: act_ge_property act_ge_property_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ge_property
    ADD CONSTRAINT act_ge_property_pkey PRIMARY KEY (name_);


--
-- Name: act_hi_actinst act_hi_actinst_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_hi_actinst
    ADD CONSTRAINT act_hi_actinst_pkey PRIMARY KEY (id_);


--
-- Name: act_hi_attachment act_hi_attachment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_hi_attachment
    ADD CONSTRAINT act_hi_attachment_pkey PRIMARY KEY (id_);


--
-- Name: act_hi_comment act_hi_comment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_hi_comment
    ADD CONSTRAINT act_hi_comment_pkey PRIMARY KEY (id_);


--
-- Name: act_hi_detail act_hi_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_hi_detail
    ADD CONSTRAINT act_hi_detail_pkey PRIMARY KEY (id_);


--
-- Name: act_hi_entitylink act_hi_entitylink_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_hi_entitylink
    ADD CONSTRAINT act_hi_entitylink_pkey PRIMARY KEY (id_);


--
-- Name: act_hi_identitylink act_hi_identitylink_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_hi_identitylink
    ADD CONSTRAINT act_hi_identitylink_pkey PRIMARY KEY (id_);


--
-- Name: act_hi_procinst act_hi_procinst_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_hi_procinst
    ADD CONSTRAINT act_hi_procinst_pkey PRIMARY KEY (id_);


--
-- Name: act_hi_procinst act_hi_procinst_proc_inst_id__key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_hi_procinst
    ADD CONSTRAINT act_hi_procinst_proc_inst_id__key UNIQUE (proc_inst_id_);


--
-- Name: act_hi_taskinst act_hi_taskinst_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_hi_taskinst
    ADD CONSTRAINT act_hi_taskinst_pkey PRIMARY KEY (id_);


--
-- Name: act_hi_tsk_log act_hi_tsk_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_hi_tsk_log
    ADD CONSTRAINT act_hi_tsk_log_pkey PRIMARY KEY (id_);


--
-- Name: act_hi_varinst act_hi_varinst_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_hi_varinst
    ADD CONSTRAINT act_hi_varinst_pkey PRIMARY KEY (id_);


--
-- Name: act_id_bytearray act_id_bytearray_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_id_bytearray
    ADD CONSTRAINT act_id_bytearray_pkey PRIMARY KEY (id_);


--
-- Name: act_id_group act_id_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_id_group
    ADD CONSTRAINT act_id_group_pkey PRIMARY KEY (id_);


--
-- Name: act_id_info act_id_info_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_id_info
    ADD CONSTRAINT act_id_info_pkey PRIMARY KEY (id_);


--
-- Name: act_id_membership act_id_membership_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_id_membership
    ADD CONSTRAINT act_id_membership_pkey PRIMARY KEY (user_id_, group_id_);


--
-- Name: act_id_priv_mapping act_id_priv_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_id_priv_mapping
    ADD CONSTRAINT act_id_priv_mapping_pkey PRIMARY KEY (id_);


--
-- Name: act_id_priv act_id_priv_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_id_priv
    ADD CONSTRAINT act_id_priv_pkey PRIMARY KEY (id_);


--
-- Name: act_id_property act_id_property_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_id_property
    ADD CONSTRAINT act_id_property_pkey PRIMARY KEY (name_);


--
-- Name: act_id_token act_id_token_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_id_token
    ADD CONSTRAINT act_id_token_pkey PRIMARY KEY (id_);


--
-- Name: act_id_user act_id_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_id_user
    ADD CONSTRAINT act_id_user_pkey PRIMARY KEY (id_);


--
-- Name: act_procdef_info act_procdef_info_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_procdef_info
    ADD CONSTRAINT act_procdef_info_pkey PRIMARY KEY (id_);


--
-- Name: act_re_deployment act_re_deployment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_re_deployment
    ADD CONSTRAINT act_re_deployment_pkey PRIMARY KEY (id_);


--
-- Name: act_re_model act_re_model_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_re_model
    ADD CONSTRAINT act_re_model_pkey PRIMARY KEY (id_);


--
-- Name: act_re_procdef act_re_procdef_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_re_procdef
    ADD CONSTRAINT act_re_procdef_pkey PRIMARY KEY (id_);


--
-- Name: act_ru_actinst act_ru_actinst_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_actinst
    ADD CONSTRAINT act_ru_actinst_pkey PRIMARY KEY (id_);


--
-- Name: act_ru_deadletter_job act_ru_deadletter_job_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_deadletter_job
    ADD CONSTRAINT act_ru_deadletter_job_pkey PRIMARY KEY (id_);


--
-- Name: act_ru_entitylink act_ru_entitylink_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_entitylink
    ADD CONSTRAINT act_ru_entitylink_pkey PRIMARY KEY (id_);


--
-- Name: act_ru_event_subscr act_ru_event_subscr_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_event_subscr
    ADD CONSTRAINT act_ru_event_subscr_pkey PRIMARY KEY (id_);


--
-- Name: act_ru_execution act_ru_execution_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_execution
    ADD CONSTRAINT act_ru_execution_pkey PRIMARY KEY (id_);


--
-- Name: act_ru_external_job act_ru_external_job_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_external_job
    ADD CONSTRAINT act_ru_external_job_pkey PRIMARY KEY (id_);


--
-- Name: act_ru_history_job act_ru_history_job_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_history_job
    ADD CONSTRAINT act_ru_history_job_pkey PRIMARY KEY (id_);


--
-- Name: act_ru_identitylink act_ru_identitylink_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_identitylink
    ADD CONSTRAINT act_ru_identitylink_pkey PRIMARY KEY (id_);


--
-- Name: act_ru_job act_ru_job_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_job
    ADD CONSTRAINT act_ru_job_pkey PRIMARY KEY (id_);


--
-- Name: act_ru_suspended_job act_ru_suspended_job_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_suspended_job
    ADD CONSTRAINT act_ru_suspended_job_pkey PRIMARY KEY (id_);


--
-- Name: act_ru_task act_ru_task_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_task
    ADD CONSTRAINT act_ru_task_pkey PRIMARY KEY (id_);


--
-- Name: act_ru_timer_job act_ru_timer_job_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_timer_job
    ADD CONSTRAINT act_ru_timer_job_pkey PRIMARY KEY (id_);


--
-- Name: act_ru_variable act_ru_variable_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_variable
    ADD CONSTRAINT act_ru_variable_pkey PRIMARY KEY (id_);


--
-- Name: act_procdef_info act_uniq_info_procdef; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_procdef_info
    ADD CONSTRAINT act_uniq_info_procdef UNIQUE (proc_def_id_);


--
-- Name: act_id_priv act_uniq_priv_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_id_priv
    ADD CONSTRAINT act_uniq_priv_name UNIQUE (name_);


--
-- Name: act_re_procdef act_uniq_procdef; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_re_procdef
    ADD CONSTRAINT act_uniq_procdef UNIQUE (key_, version_, derived_version_, tenant_id_);


--
-- Name: ai_api_key ai_api_key_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_api_key
    ADD CONSTRAINT ai_api_key_pkey PRIMARY KEY (id);


--
-- Name: ai_chat_conversation ai_chat_conversation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_chat_conversation
    ADD CONSTRAINT ai_chat_conversation_pkey PRIMARY KEY (id);


--
-- Name: ai_chat_message ai_chat_message_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_chat_message
    ADD CONSTRAINT ai_chat_message_pkey PRIMARY KEY (id);


--
-- Name: ai_chat_role ai_chat_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_chat_role
    ADD CONSTRAINT ai_chat_role_pkey PRIMARY KEY (id);


--
-- Name: ai_image ai_image_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_image
    ADD CONSTRAINT ai_image_pkey PRIMARY KEY (id);


--
-- Name: ai_knowledge_document ai_knowledge_document_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_knowledge_document
    ADD CONSTRAINT ai_knowledge_document_pkey PRIMARY KEY (id);


--
-- Name: ai_knowledge ai_knowledge_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_knowledge
    ADD CONSTRAINT ai_knowledge_pkey PRIMARY KEY (id);


--
-- Name: ai_knowledge_segment ai_knowledge_segment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_knowledge_segment
    ADD CONSTRAINT ai_knowledge_segment_pkey PRIMARY KEY (id);


--
-- Name: ai_mind_map ai_mind_map_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_mind_map
    ADD CONSTRAINT ai_mind_map_pkey PRIMARY KEY (id);


--
-- Name: ai_model ai_model_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_model
    ADD CONSTRAINT ai_model_pkey PRIMARY KEY (id);


--
-- Name: ai_music ai_music_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_music
    ADD CONSTRAINT ai_music_pkey PRIMARY KEY (id);


--
-- Name: ai_tool ai_tool_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_tool
    ADD CONSTRAINT ai_tool_pkey PRIMARY KEY (id);


--
-- Name: ai_workflow ai_workflow_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_workflow
    ADD CONSTRAINT ai_workflow_pkey PRIMARY KEY (id);


--
-- Name: ai_write ai_write_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_write
    ADD CONSTRAINT ai_write_pkey PRIMARY KEY (id);


--
-- Name: bpm_category bpm_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bpm_category
    ADD CONSTRAINT bpm_category_pkey PRIMARY KEY (id);


--
-- Name: bpm_form bpm_form_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bpm_form
    ADD CONSTRAINT bpm_form_pkey PRIMARY KEY (id);


--
-- Name: bpm_oa_leave bpm_oa_leave_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bpm_oa_leave
    ADD CONSTRAINT bpm_oa_leave_pkey PRIMARY KEY (id);


--
-- Name: bpm_process_definition_info bpm_process_definition_info_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bpm_process_definition_info
    ADD CONSTRAINT bpm_process_definition_info_pkey PRIMARY KEY (id);


--
-- Name: bpm_process_expression bpm_process_expression_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bpm_process_expression
    ADD CONSTRAINT bpm_process_expression_pkey PRIMARY KEY (id);


--
-- Name: bpm_process_instance_copy bpm_process_instance_copy_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bpm_process_instance_copy
    ADD CONSTRAINT bpm_process_instance_copy_pkey PRIMARY KEY (id);


--
-- Name: bpm_process_listener bpm_process_listener_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bpm_process_listener
    ADD CONSTRAINT bpm_process_listener_pkey PRIMARY KEY (id);


--
-- Name: bpm_user_group bpm_user_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bpm_user_group
    ADD CONSTRAINT bpm_user_group_pkey PRIMARY KEY (id);


--
-- Name: dual dual_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dual
    ADD CONSTRAINT dual_pkey PRIMARY KEY (id);


--
-- Name: erp_account erp_account_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_account
    ADD CONSTRAINT erp_account_pkey PRIMARY KEY (id);


--
-- Name: erp_customer erp_customer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_customer
    ADD CONSTRAINT erp_customer_pkey PRIMARY KEY (id);


--
-- Name: erp_finance_payment_item erp_finance_payment_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_finance_payment_item
    ADD CONSTRAINT erp_finance_payment_item_pkey PRIMARY KEY (id);


--
-- Name: erp_finance_payment erp_finance_payment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_finance_payment
    ADD CONSTRAINT erp_finance_payment_pkey PRIMARY KEY (id);


--
-- Name: erp_finance_receipt_item erp_finance_receipt_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_finance_receipt_item
    ADD CONSTRAINT erp_finance_receipt_item_pkey PRIMARY KEY (id);


--
-- Name: erp_finance_receipt erp_finance_receipt_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_finance_receipt
    ADD CONSTRAINT erp_finance_receipt_pkey PRIMARY KEY (id);


--
-- Name: erp_product_category erp_product_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_product_category
    ADD CONSTRAINT erp_product_category_pkey PRIMARY KEY (id);


--
-- Name: erp_product erp_product_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_product
    ADD CONSTRAINT erp_product_pkey PRIMARY KEY (id);


--
-- Name: erp_product_unit erp_product_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_product_unit
    ADD CONSTRAINT erp_product_unit_pkey PRIMARY KEY (id);


--
-- Name: erp_purchase_in_items erp_purchase_in_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_purchase_in_items
    ADD CONSTRAINT erp_purchase_in_items_pkey PRIMARY KEY (id);


--
-- Name: erp_purchase_in erp_purchase_in_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_purchase_in
    ADD CONSTRAINT erp_purchase_in_pkey PRIMARY KEY (id);


--
-- Name: erp_purchase_order_items erp_purchase_order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_purchase_order_items
    ADD CONSTRAINT erp_purchase_order_items_pkey PRIMARY KEY (id);


--
-- Name: erp_purchase_order erp_purchase_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_purchase_order
    ADD CONSTRAINT erp_purchase_order_pkey PRIMARY KEY (id);


--
-- Name: erp_purchase_return_items erp_purchase_return_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_purchase_return_items
    ADD CONSTRAINT erp_purchase_return_items_pkey PRIMARY KEY (id);


--
-- Name: erp_purchase_return erp_purchase_return_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_purchase_return
    ADD CONSTRAINT erp_purchase_return_pkey PRIMARY KEY (id);


--
-- Name: erp_sale_order_items erp_sale_order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_sale_order_items
    ADD CONSTRAINT erp_sale_order_items_pkey PRIMARY KEY (id);


--
-- Name: erp_sale_order erp_sale_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_sale_order
    ADD CONSTRAINT erp_sale_order_pkey PRIMARY KEY (id);


--
-- Name: erp_sale_out_items erp_sale_out_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_sale_out_items
    ADD CONSTRAINT erp_sale_out_items_pkey PRIMARY KEY (id);


--
-- Name: erp_sale_out erp_sale_out_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_sale_out
    ADD CONSTRAINT erp_sale_out_pkey PRIMARY KEY (id);


--
-- Name: erp_sale_return_items erp_sale_return_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_sale_return_items
    ADD CONSTRAINT erp_sale_return_items_pkey PRIMARY KEY (id);


--
-- Name: erp_sale_return erp_sale_return_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_sale_return
    ADD CONSTRAINT erp_sale_return_pkey PRIMARY KEY (id);


--
-- Name: erp_stock_batch erp_stock_batch_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_stock_batch
    ADD CONSTRAINT erp_stock_batch_pkey PRIMARY KEY (id);


--
-- Name: erp_stock_check_item erp_stock_check_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_stock_check_item
    ADD CONSTRAINT erp_stock_check_item_pkey PRIMARY KEY (id);


--
-- Name: erp_stock_check erp_stock_check_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_stock_check
    ADD CONSTRAINT erp_stock_check_pkey PRIMARY KEY (id);


--
-- Name: erp_stock_in_item erp_stock_in_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_stock_in_item
    ADD CONSTRAINT erp_stock_in_item_pkey PRIMARY KEY (id);


--
-- Name: erp_stock_in erp_stock_in_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_stock_in
    ADD CONSTRAINT erp_stock_in_pkey PRIMARY KEY (id);


--
-- Name: erp_stock_move_item erp_stock_move_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_stock_move_item
    ADD CONSTRAINT erp_stock_move_item_pkey PRIMARY KEY (id);


--
-- Name: erp_stock_move erp_stock_move_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_stock_move
    ADD CONSTRAINT erp_stock_move_pkey PRIMARY KEY (id);


--
-- Name: erp_stock_out_item erp_stock_out_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_stock_out_item
    ADD CONSTRAINT erp_stock_out_item_pkey PRIMARY KEY (id);


--
-- Name: erp_stock_out erp_stock_out_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_stock_out
    ADD CONSTRAINT erp_stock_out_pkey PRIMARY KEY (id);


--
-- Name: erp_stock erp_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_stock
    ADD CONSTRAINT erp_stock_pkey PRIMARY KEY (id);


--
-- Name: erp_stock_record erp_stock_record_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_stock_record
    ADD CONSTRAINT erp_stock_record_pkey PRIMARY KEY (id);


--
-- Name: erp_supplier erp_supplier_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_supplier
    ADD CONSTRAINT erp_supplier_pkey PRIMARY KEY (id);


--
-- Name: erp_warehouse erp_warehouse_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_warehouse
    ADD CONSTRAINT erp_warehouse_pkey PRIMARY KEY (id);


--
-- Name: flw_ru_batch_part flw_ru_batch_part_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flw_ru_batch_part
    ADD CONSTRAINT flw_ru_batch_part_pkey PRIMARY KEY (id_);


--
-- Name: flw_ru_batch flw_ru_batch_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flw_ru_batch
    ADD CONSTRAINT flw_ru_batch_pkey PRIMARY KEY (id_);


--
-- Name: fms_account_set fms_account_set_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_account_set
    ADD CONSTRAINT fms_account_set_pkey PRIMARY KEY (id);


--
-- Name: fms_account_user fms_account_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_account_user
    ADD CONSTRAINT fms_account_user_pkey PRIMARY KEY (id);


--
-- Name: fms_assist_combination fms_assist_combination_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_assist_combination
    ADD CONSTRAINT fms_assist_combination_pkey PRIMARY KEY (id);


--
-- Name: fms_auxiliary_item fms_auxiliary_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_auxiliary_item
    ADD CONSTRAINT fms_auxiliary_item_pkey PRIMARY KEY (id);


--
-- Name: fms_auxiliary_type fms_auxiliary_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_auxiliary_type
    ADD CONSTRAINT fms_auxiliary_type_pkey PRIMARY KEY (id);


--
-- Name: fms_balance_sheet_config fms_balance_sheet_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_balance_sheet_config
    ADD CONSTRAINT fms_balance_sheet_config_pkey PRIMARY KEY (id);


--
-- Name: fms_balance_sheet_report fms_balance_sheet_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_balance_sheet_report
    ADD CONSTRAINT fms_balance_sheet_report_pkey PRIMARY KEY (id);


--
-- Name: fms_cash_flow_extend_config fms_cash_flow_extend_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_cash_flow_extend_config
    ADD CONSTRAINT fms_cash_flow_extend_config_pkey PRIMARY KEY (id);


--
-- Name: fms_cash_flow_extend_data fms_cash_flow_extend_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_cash_flow_extend_data
    ADD CONSTRAINT fms_cash_flow_extend_data_pkey PRIMARY KEY (id);


--
-- Name: fms_cash_flow_statement_config fms_cash_flow_statement_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_cash_flow_statement_config
    ADD CONSTRAINT fms_cash_flow_statement_config_pkey PRIMARY KEY (id);


--
-- Name: fms_cash_flow_statement_report fms_cash_flow_statement_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_cash_flow_statement_report
    ADD CONSTRAINT fms_cash_flow_statement_report_pkey PRIMARY KEY (id);


--
-- Name: fms_closing_period fms_closing_period_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_closing_period
    ADD CONSTRAINT fms_closing_period_pkey PRIMARY KEY (id);


--
-- Name: fms_closing fms_closing_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_closing
    ADD CONSTRAINT fms_closing_pkey PRIMARY KEY (id);


--
-- Name: fms_closing_template fms_closing_template_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_closing_template
    ADD CONSTRAINT fms_closing_template_pkey PRIMARY KEY (id);


--
-- Name: fms_closing_voucher fms_closing_voucher_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_closing_voucher
    ADD CONSTRAINT fms_closing_voucher_pkey PRIMARY KEY (id);


--
-- Name: fms_currency fms_currency_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_currency
    ADD CONSTRAINT fms_currency_pkey PRIMARY KEY (id);


--
-- Name: fms_digest fms_digest_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_digest
    ADD CONSTRAINT fms_digest_pkey PRIMARY KEY (id);


--
-- Name: fms_finance_indicator fms_finance_indicator_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_finance_indicator
    ADD CONSTRAINT fms_finance_indicator_pkey PRIMARY KEY (id);


--
-- Name: fms_finance_parameter fms_finance_parameter_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_finance_parameter
    ADD CONSTRAINT fms_finance_parameter_pkey PRIMARY KEY (id);


--
-- Name: fms_income_statement_config fms_income_statement_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_income_statement_config
    ADD CONSTRAINT fms_income_statement_config_pkey PRIMARY KEY (id);


--
-- Name: fms_income_statement_report fms_income_statement_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_income_statement_report
    ADD CONSTRAINT fms_income_statement_report_pkey PRIMARY KEY (id);


--
-- Name: fms_initial_balance fms_initial_balance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_initial_balance
    ADD CONSTRAINT fms_initial_balance_pkey PRIMARY KEY (id);


--
-- Name: fms_report_template fms_report_template_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_report_template
    ADD CONSTRAINT fms_report_template_pkey PRIMARY KEY (id);


--
-- Name: fms_subject fms_subject_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_subject
    ADD CONSTRAINT fms_subject_pkey PRIMARY KEY (id);


--
-- Name: fms_subject_template fms_subject_template_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_subject_template
    ADD CONSTRAINT fms_subject_template_pkey PRIMARY KEY (id);


--
-- Name: fms_voucher_entry fms_voucher_entry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_voucher_entry
    ADD CONSTRAINT fms_voucher_entry_pkey PRIMARY KEY (id);


--
-- Name: fms_voucher fms_voucher_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_voucher
    ADD CONSTRAINT fms_voucher_pkey PRIMARY KEY (id);


--
-- Name: fms_voucher_template_category fms_voucher_template_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_voucher_template_category
    ADD CONSTRAINT fms_voucher_template_category_pkey PRIMARY KEY (id);


--
-- Name: fms_voucher_template fms_voucher_template_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_voucher_template
    ADD CONSTRAINT fms_voucher_template_pkey PRIMARY KEY (id);


--
-- Name: fms_voucher_word fms_voucher_word_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fms_voucher_word
    ADD CONSTRAINT fms_voucher_word_pkey PRIMARY KEY (id);


--
-- Name: member_user member_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_user
    ADD CONSTRAINT member_user_pkey PRIMARY KEY (id);


--
-- Name: bill_ext pk_bill_ext; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_ext
    ADD CONSTRAINT pk_bill_ext PRIMARY KEY (id);


--
-- Name: bill_log pk_bill_log; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_log
    ADD CONSTRAINT pk_bill_log PRIMARY KEY (id);


--
-- Name: bill_no_seq pk_bill_no_seq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_no_seq
    ADD CONSTRAINT pk_bill_no_seq PRIMARY KEY (id);


--
-- Name: bill_relation pk_bill_relation; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_relation
    ADD CONSTRAINT pk_bill_relation PRIMARY KEY (id);


--
-- Name: bill_type pk_bill_type; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_type
    ADD CONSTRAINT pk_bill_type PRIMARY KEY (id);


--
-- Name: erp_customer_account pk_erp_customer_account; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_customer_account
    ADD CONSTRAINT pk_erp_customer_account PRIMARY KEY (id);


--
-- Name: erp_price_list_item_log pk_erp_price_list_item_log; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_price_list_item_log
    ADD CONSTRAINT pk_erp_price_list_item_log PRIMARY KEY (id);


--
-- Name: erp_price_list_scope pk_erp_price_list_scope; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_price_list_scope
    ADD CONSTRAINT pk_erp_price_list_scope PRIMARY KEY (id);


--
-- Name: erp_price_list pk_erp_purchase_price; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_price_list
    ADD CONSTRAINT pk_erp_purchase_price PRIMARY KEY (id);


--
-- Name: erp_price_list_item pk_erp_purchase_price_item; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erp_price_list_item
    ADD CONSTRAINT pk_erp_purchase_price_item PRIMARY KEY (id);


--
-- Name: infra_api_access_log pk_infra_api_access_log; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.infra_api_access_log
    ADD CONSTRAINT pk_infra_api_access_log PRIMARY KEY (id);


--
-- Name: infra_api_error_log pk_infra_api_error_log; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.infra_api_error_log
    ADD CONSTRAINT pk_infra_api_error_log PRIMARY KEY (id);


--
-- Name: infra_config pk_infra_config; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.infra_config
    ADD CONSTRAINT pk_infra_config PRIMARY KEY (id);


--
-- Name: infra_file pk_infra_file; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.infra_file
    ADD CONSTRAINT pk_infra_file PRIMARY KEY (id);


--
-- Name: infra_file_config pk_infra_file_config; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.infra_file_config
    ADD CONSTRAINT pk_infra_file_config PRIMARY KEY (id);


--
-- Name: infra_file_content pk_infra_file_content; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.infra_file_content
    ADD CONSTRAINT pk_infra_file_content PRIMARY KEY (id);


--
-- Name: infra_job pk_infra_job; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.infra_job
    ADD CONSTRAINT pk_infra_job PRIMARY KEY (id);


--
-- Name: infra_job_log pk_infra_job_log; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.infra_job_log
    ADD CONSTRAINT pk_infra_job_log PRIMARY KEY (id);


--
-- Name: member_user_store pk_member_user_store; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_user_store
    ADD CONSTRAINT pk_member_user_store PRIMARY KEY (id);


--
-- Name: system_code_rule pk_system_code_rule; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_code_rule
    ADD CONSTRAINT pk_system_code_rule PRIMARY KEY (id);


--
-- Name: system_dept pk_system_dept; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_dept
    ADD CONSTRAINT pk_system_dept PRIMARY KEY (id);


--
-- Name: system_dict_data pk_system_dict_data; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_dict_data
    ADD CONSTRAINT pk_system_dict_data PRIMARY KEY (id);


--
-- Name: system_dict_type pk_system_dict_type; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_dict_type
    ADD CONSTRAINT pk_system_dict_type PRIMARY KEY (id);


--
-- Name: system_login_log pk_system_login_log; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_login_log
    ADD CONSTRAINT pk_system_login_log PRIMARY KEY (id);


--
-- Name: system_mail_account pk_system_mail_account; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_mail_account
    ADD CONSTRAINT pk_system_mail_account PRIMARY KEY (id);


--
-- Name: system_mail_log pk_system_mail_log; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_mail_log
    ADD CONSTRAINT pk_system_mail_log PRIMARY KEY (id);


--
-- Name: system_mail_template pk_system_mail_template; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_mail_template
    ADD CONSTRAINT pk_system_mail_template PRIMARY KEY (id);


--
-- Name: system_menu pk_system_menu; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_menu
    ADD CONSTRAINT pk_system_menu PRIMARY KEY (id);


--
-- Name: system_notice pk_system_notice; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_notice
    ADD CONSTRAINT pk_system_notice PRIMARY KEY (id);


--
-- Name: system_notify_message pk_system_notify_message; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_notify_message
    ADD CONSTRAINT pk_system_notify_message PRIMARY KEY (id);


--
-- Name: system_notify_template pk_system_notify_template; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_notify_template
    ADD CONSTRAINT pk_system_notify_template PRIMARY KEY (id);


--
-- Name: system_oauth2_access_token pk_system_oauth2_access_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_oauth2_access_token
    ADD CONSTRAINT pk_system_oauth2_access_token PRIMARY KEY (id);


--
-- Name: system_oauth2_approve pk_system_oauth2_approve; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_oauth2_approve
    ADD CONSTRAINT pk_system_oauth2_approve PRIMARY KEY (id);


--
-- Name: system_oauth2_client pk_system_oauth2_client; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_oauth2_client
    ADD CONSTRAINT pk_system_oauth2_client PRIMARY KEY (id);


--
-- Name: system_oauth2_code pk_system_oauth2_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_oauth2_code
    ADD CONSTRAINT pk_system_oauth2_code PRIMARY KEY (id);


--
-- Name: system_oauth2_refresh_token pk_system_oauth2_refresh_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_oauth2_refresh_token
    ADD CONSTRAINT pk_system_oauth2_refresh_token PRIMARY KEY (id);


--
-- Name: system_operate_log pk_system_operate_log; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_operate_log
    ADD CONSTRAINT pk_system_operate_log PRIMARY KEY (id);


--
-- Name: system_post pk_system_post; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_post
    ADD CONSTRAINT pk_system_post PRIMARY KEY (id);


--
-- Name: system_role pk_system_role; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_role
    ADD CONSTRAINT pk_system_role PRIMARY KEY (id);


--
-- Name: system_role_menu pk_system_role_menu; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_role_menu
    ADD CONSTRAINT pk_system_role_menu PRIMARY KEY (id);


--
-- Name: system_sms_channel pk_system_sms_channel; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_sms_channel
    ADD CONSTRAINT pk_system_sms_channel PRIMARY KEY (id);


--
-- Name: system_sms_code pk_system_sms_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_sms_code
    ADD CONSTRAINT pk_system_sms_code PRIMARY KEY (id);


--
-- Name: system_sms_log pk_system_sms_log; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_sms_log
    ADD CONSTRAINT pk_system_sms_log PRIMARY KEY (id);


--
-- Name: system_sms_template pk_system_sms_template; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_sms_template
    ADD CONSTRAINT pk_system_sms_template PRIMARY KEY (id);


--
-- Name: system_social_client pk_system_social_client; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_social_client
    ADD CONSTRAINT pk_system_social_client PRIMARY KEY (id);


--
-- Name: system_social_user pk_system_social_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_social_user
    ADD CONSTRAINT pk_system_social_user PRIMARY KEY (id);


--
-- Name: system_social_user_bind pk_system_social_user_bind; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_social_user_bind
    ADD CONSTRAINT pk_system_social_user_bind PRIMARY KEY (id);


--
-- Name: system_tenant pk_system_tenant; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_tenant
    ADD CONSTRAINT pk_system_tenant PRIMARY KEY (id);


--
-- Name: system_tenant_package pk_system_tenant_package; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_tenant_package
    ADD CONSTRAINT pk_system_tenant_package PRIMARY KEY (id);


--
-- Name: system_user_post pk_system_user_post; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_user_post
    ADD CONSTRAINT pk_system_user_post PRIMARY KEY (id);


--
-- Name: system_user_role pk_system_user_role; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_user_role
    ADD CONSTRAINT pk_system_user_role PRIMARY KEY (id);


--
-- Name: system_users pk_system_users; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_users
    ADD CONSTRAINT pk_system_users PRIMARY KEY (id);


--
-- Name: trade_order_receipt pk_trade_order_receipt; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_order_receipt
    ADD CONSTRAINT pk_trade_order_receipt PRIMARY KEY (id);


--
-- Name: trade_order_receipt_item pk_trade_order_receipt_item; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_order_receipt_item
    ADD CONSTRAINT pk_trade_order_receipt_item PRIMARY KEY (id);


--
-- Name: product_brand product_brand_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_brand
    ADD CONSTRAINT product_brand_pkey PRIMARY KEY (id);


--
-- Name: product_browse_history product_browse_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_browse_history
    ADD CONSTRAINT product_browse_history_pkey PRIMARY KEY (id);


--
-- Name: product_category product_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_category
    ADD CONSTRAINT product_category_pkey PRIMARY KEY (id);


--
-- Name: product_favorite product_favorite_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_favorite
    ADD CONSTRAINT product_favorite_pkey PRIMARY KEY (id);


--
-- Name: product_property product_property_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_property
    ADD CONSTRAINT product_property_pkey PRIMARY KEY (id);


--
-- Name: product_property_value product_property_value_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_property_value
    ADD CONSTRAINT product_property_value_pkey PRIMARY KEY (id);


--
-- Name: product_sku product_sku_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_sku
    ADD CONSTRAINT product_sku_pkey PRIMARY KEY (id);


--
-- Name: product_spu product_spu_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_spu
    ADD CONSTRAINT product_spu_pkey PRIMARY KEY (id);


--
-- Name: product_statistics product_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_statistics
    ADD CONSTRAINT product_statistics_pkey PRIMARY KEY (id);


--
-- Name: qrtz_blob_triggers qrtz_blob_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_blob_triggers
    ADD CONSTRAINT qrtz_blob_triggers_pkey PRIMARY KEY (sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_calendars qrtz_calendars_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_calendars
    ADD CONSTRAINT qrtz_calendars_pkey PRIMARY KEY (sched_name, calendar_name);


--
-- Name: qrtz_cron_triggers qrtz_cron_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_cron_triggers
    ADD CONSTRAINT qrtz_cron_triggers_pkey PRIMARY KEY (sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_fired_triggers qrtz_fired_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_fired_triggers
    ADD CONSTRAINT qrtz_fired_triggers_pkey PRIMARY KEY (sched_name, entry_id);


--
-- Name: qrtz_job_details qrtz_job_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_job_details
    ADD CONSTRAINT qrtz_job_details_pkey PRIMARY KEY (sched_name, job_name, job_group);


--
-- Name: qrtz_locks qrtz_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_locks
    ADD CONSTRAINT qrtz_locks_pkey PRIMARY KEY (sched_name, lock_name);


--
-- Name: qrtz_paused_trigger_grps qrtz_paused_trigger_grps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_paused_trigger_grps
    ADD CONSTRAINT qrtz_paused_trigger_grps_pkey PRIMARY KEY (sched_name, trigger_group);


--
-- Name: qrtz_scheduler_state qrtz_scheduler_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_scheduler_state
    ADD CONSTRAINT qrtz_scheduler_state_pkey PRIMARY KEY (sched_name, instance_name);


--
-- Name: qrtz_simple_triggers qrtz_simple_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_simple_triggers
    ADD CONSTRAINT qrtz_simple_triggers_pkey PRIMARY KEY (sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_simprop_triggers qrtz_simprop_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_simprop_triggers
    ADD CONSTRAINT qrtz_simprop_triggers_pkey PRIMARY KEY (sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_triggers qrtz_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_triggers
    ADD CONSTRAINT qrtz_triggers_pkey PRIMARY KEY (sched_name, trigger_name, trigger_group);


--
-- Name: trade_after_sale_log trade_after_sale_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_after_sale_log
    ADD CONSTRAINT trade_after_sale_log_pkey PRIMARY KEY (id);


--
-- Name: trade_after_sale trade_after_sale_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_after_sale
    ADD CONSTRAINT trade_after_sale_pkey PRIMARY KEY (id);


--
-- Name: trade_cart trade_cart_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_cart
    ADD CONSTRAINT trade_cart_pkey PRIMARY KEY (id);


--
-- Name: trade_config trade_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_config
    ADD CONSTRAINT trade_config_pkey PRIMARY KEY (id);


--
-- Name: trade_delivery_express trade_delivery_express_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_delivery_express
    ADD CONSTRAINT trade_delivery_express_pkey PRIMARY KEY (id);


--
-- Name: trade_delivery_express_template_charge trade_delivery_express_template_charge_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_delivery_express_template_charge
    ADD CONSTRAINT trade_delivery_express_template_charge_pkey PRIMARY KEY (id);


--
-- Name: trade_delivery_express_template_free trade_delivery_express_template_free_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_delivery_express_template_free
    ADD CONSTRAINT trade_delivery_express_template_free_pkey PRIMARY KEY (id);


--
-- Name: trade_delivery_express_template trade_delivery_express_template_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_delivery_express_template
    ADD CONSTRAINT trade_delivery_express_template_pkey PRIMARY KEY (id);


--
-- Name: trade_order_item trade_order_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_order_item
    ADD CONSTRAINT trade_order_item_pkey PRIMARY KEY (id);


--
-- Name: trade_order_log trade_order_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_order_log
    ADD CONSTRAINT trade_order_log_pkey PRIMARY KEY (id);


--
-- Name: trade_order trade_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_order
    ADD CONSTRAINT trade_order_pkey PRIMARY KEY (id);


--
-- Name: trade_statistics trade_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_statistics
    ADD CONSTRAINT trade_statistics_pkey PRIMARY KEY (id);


--
-- Name: wms_check_order_detail wms_check_order_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_check_order_detail
    ADD CONSTRAINT wms_check_order_detail_pkey PRIMARY KEY (id);


--
-- Name: wms_check_order wms_check_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_check_order
    ADD CONSTRAINT wms_check_order_pkey PRIMARY KEY (id);


--
-- Name: wms_inventory_history wms_inventory_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_inventory_history
    ADD CONSTRAINT wms_inventory_history_pkey PRIMARY KEY (id);


--
-- Name: wms_inventory wms_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_inventory
    ADD CONSTRAINT wms_inventory_pkey PRIMARY KEY (id);


--
-- Name: wms_item_brand wms_item_brand_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_item_brand
    ADD CONSTRAINT wms_item_brand_pkey PRIMARY KEY (id);


--
-- Name: wms_item_category wms_item_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_item_category
    ADD CONSTRAINT wms_item_category_pkey PRIMARY KEY (id);


--
-- Name: wms_item wms_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_item
    ADD CONSTRAINT wms_item_pkey PRIMARY KEY (id);


--
-- Name: wms_item_sku wms_item_sku_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_item_sku
    ADD CONSTRAINT wms_item_sku_pkey PRIMARY KEY (id);


--
-- Name: wms_merchant wms_merchant_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_merchant
    ADD CONSTRAINT wms_merchant_pkey PRIMARY KEY (id);


--
-- Name: wms_movement_order_detail wms_movement_order_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_movement_order_detail
    ADD CONSTRAINT wms_movement_order_detail_pkey PRIMARY KEY (id);


--
-- Name: wms_movement_order wms_movement_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_movement_order
    ADD CONSTRAINT wms_movement_order_pkey PRIMARY KEY (id);


--
-- Name: wms_receipt_order_detail wms_receipt_order_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_receipt_order_detail
    ADD CONSTRAINT wms_receipt_order_detail_pkey PRIMARY KEY (id);


--
-- Name: wms_receipt_order wms_receipt_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_receipt_order
    ADD CONSTRAINT wms_receipt_order_pkey PRIMARY KEY (id);


--
-- Name: wms_shipment_order_detail wms_shipment_order_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_shipment_order_detail
    ADD CONSTRAINT wms_shipment_order_detail_pkey PRIMARY KEY (id);


--
-- Name: wms_shipment_order wms_shipment_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_shipment_order
    ADD CONSTRAINT wms_shipment_order_pkey PRIMARY KEY (id);


--
-- Name: wms_warehouse wms_warehouse_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wms_warehouse
    ADD CONSTRAINT wms_warehouse_pkey PRIMARY KEY (id);


--
-- Name: act_idx_act_hi_tsk_log_task; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_act_hi_tsk_log_task ON public.act_hi_tsk_log USING btree (task_id_);


--
-- Name: act_idx_athrz_procedef; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_athrz_procedef ON public.act_ru_identitylink USING btree (proc_def_id_);


--
-- Name: act_idx_bytear_depl; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_bytear_depl ON public.act_ge_bytearray USING btree (deployment_id_);


--
-- Name: act_idx_channel_def_uniq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX act_idx_channel_def_uniq ON public.flw_channel_definition USING btree (key_, version_, tenant_id_);


--
-- Name: act_idx_deadletter_job_correlation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_deadletter_job_correlation_id ON public.act_ru_deadletter_job USING btree (correlation_id_);


--
-- Name: act_idx_deadletter_job_custom_values_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_deadletter_job_custom_values_id ON public.act_ru_deadletter_job USING btree (custom_values_id_);


--
-- Name: act_idx_deadletter_job_exception_stack_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_deadletter_job_exception_stack_id ON public.act_ru_deadletter_job USING btree (exception_stack_id_);


--
-- Name: act_idx_deadletter_job_execution_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_deadletter_job_execution_id ON public.act_ru_deadletter_job USING btree (execution_id_);


--
-- Name: act_idx_deadletter_job_proc_def_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_deadletter_job_proc_def_id ON public.act_ru_deadletter_job USING btree (proc_def_id_);


--
-- Name: act_idx_deadletter_job_process_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_deadletter_job_process_instance_id ON public.act_ru_deadletter_job USING btree (process_instance_id_);


--
-- Name: act_idx_djob_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_djob_scope ON public.act_ru_deadletter_job USING btree (scope_id_, scope_type_);


--
-- Name: act_idx_djob_scope_def; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_djob_scope_def ON public.act_ru_deadletter_job USING btree (scope_definition_id_, scope_type_);


--
-- Name: act_idx_djob_sub_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_djob_sub_scope ON public.act_ru_deadletter_job USING btree (sub_scope_id_, scope_type_);


--
-- Name: act_idx_ejob_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ejob_scope ON public.act_ru_external_job USING btree (scope_id_, scope_type_);


--
-- Name: act_idx_ejob_scope_def; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ejob_scope_def ON public.act_ru_external_job USING btree (scope_definition_id_, scope_type_);


--
-- Name: act_idx_ejob_sub_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ejob_sub_scope ON public.act_ru_external_job USING btree (sub_scope_id_, scope_type_);


--
-- Name: act_idx_ent_lnk_ref_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ent_lnk_ref_scope ON public.act_ru_entitylink USING btree (ref_scope_id_, ref_scope_type_, link_type_);


--
-- Name: act_idx_ent_lnk_root_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ent_lnk_root_scope ON public.act_ru_entitylink USING btree (root_scope_id_, root_scope_type_, link_type_);


--
-- Name: act_idx_ent_lnk_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ent_lnk_scope ON public.act_ru_entitylink USING btree (scope_id_, scope_type_, link_type_);


--
-- Name: act_idx_ent_lnk_scope_def; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ent_lnk_scope_def ON public.act_ru_entitylink USING btree (scope_definition_id_, scope_type_, link_type_);


--
-- Name: act_idx_event_def_uniq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX act_idx_event_def_uniq ON public.flw_event_definition USING btree (key_, version_, tenant_id_);


--
-- Name: act_idx_event_subscr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_event_subscr ON public.act_ru_event_subscr USING btree (execution_id_);


--
-- Name: act_idx_event_subscr_config_; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_event_subscr_config_ ON public.act_ru_event_subscr USING btree (configuration_);


--
-- Name: act_idx_event_subscr_proc_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_event_subscr_proc_id ON public.act_ru_event_subscr USING btree (proc_inst_id_);


--
-- Name: act_idx_event_subscr_scoperef_; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_event_subscr_scoperef_ ON public.act_ru_event_subscr USING btree (scope_id_, scope_type_);


--
-- Name: act_idx_exe_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_exe_parent ON public.act_ru_execution USING btree (parent_id_);


--
-- Name: act_idx_exe_procdef; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_exe_procdef ON public.act_ru_execution USING btree (proc_def_id_);


--
-- Name: act_idx_exe_procinst; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_exe_procinst ON public.act_ru_execution USING btree (proc_inst_id_);


--
-- Name: act_idx_exe_root; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_exe_root ON public.act_ru_execution USING btree (root_proc_inst_id_);


--
-- Name: act_idx_exe_super; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_exe_super ON public.act_ru_execution USING btree (super_exec_);


--
-- Name: act_idx_exec_buskey; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_exec_buskey ON public.act_ru_execution USING btree (business_key_);


--
-- Name: act_idx_exec_ref_id_; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_exec_ref_id_ ON public.act_ru_execution USING btree (reference_id_);


--
-- Name: act_idx_external_job_correlation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_external_job_correlation_id ON public.act_ru_external_job USING btree (correlation_id_);


--
-- Name: act_idx_external_job_custom_values_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_external_job_custom_values_id ON public.act_ru_external_job USING btree (custom_values_id_);


--
-- Name: act_idx_external_job_exception_stack_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_external_job_exception_stack_id ON public.act_ru_external_job USING btree (exception_stack_id_);


--
-- Name: act_idx_hi_act_inst_end; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_act_inst_end ON public.act_hi_actinst USING btree (end_time_);


--
-- Name: act_idx_hi_act_inst_exec; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_act_inst_exec ON public.act_hi_actinst USING btree (execution_id_, act_id_);


--
-- Name: act_idx_hi_act_inst_procinst; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_act_inst_procinst ON public.act_hi_actinst USING btree (proc_inst_id_, act_id_);


--
-- Name: act_idx_hi_act_inst_start; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_act_inst_start ON public.act_hi_actinst USING btree (start_time_);


--
-- Name: act_idx_hi_detail_act_inst; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_detail_act_inst ON public.act_hi_detail USING btree (act_inst_id_);


--
-- Name: act_idx_hi_detail_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_detail_name ON public.act_hi_detail USING btree (name_);


--
-- Name: act_idx_hi_detail_proc_inst; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_detail_proc_inst ON public.act_hi_detail USING btree (proc_inst_id_);


--
-- Name: act_idx_hi_detail_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_detail_task_id ON public.act_hi_detail USING btree (task_id_);


--
-- Name: act_idx_hi_detail_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_detail_time ON public.act_hi_detail USING btree (time_);


--
-- Name: act_idx_hi_ent_lnk_ref_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_ent_lnk_ref_scope ON public.act_hi_entitylink USING btree (ref_scope_id_, ref_scope_type_, link_type_);


--
-- Name: act_idx_hi_ent_lnk_root_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_ent_lnk_root_scope ON public.act_hi_entitylink USING btree (root_scope_id_, root_scope_type_, link_type_);


--
-- Name: act_idx_hi_ent_lnk_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_ent_lnk_scope ON public.act_hi_entitylink USING btree (scope_id_, scope_type_, link_type_);


--
-- Name: act_idx_hi_ent_lnk_scope_def; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_ent_lnk_scope_def ON public.act_hi_entitylink USING btree (scope_definition_id_, scope_type_, link_type_);


--
-- Name: act_idx_hi_ident_lnk_procinst; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_ident_lnk_procinst ON public.act_hi_identitylink USING btree (proc_inst_id_);


--
-- Name: act_idx_hi_ident_lnk_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_ident_lnk_scope ON public.act_hi_identitylink USING btree (scope_id_, scope_type_);


--
-- Name: act_idx_hi_ident_lnk_scope_def; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_ident_lnk_scope_def ON public.act_hi_identitylink USING btree (scope_definition_id_, scope_type_);


--
-- Name: act_idx_hi_ident_lnk_sub_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_ident_lnk_sub_scope ON public.act_hi_identitylink USING btree (sub_scope_id_, scope_type_);


--
-- Name: act_idx_hi_ident_lnk_task; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_ident_lnk_task ON public.act_hi_identitylink USING btree (task_id_);


--
-- Name: act_idx_hi_ident_lnk_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_ident_lnk_user ON public.act_hi_identitylink USING btree (user_id_);


--
-- Name: act_idx_hi_pro_i_buskey; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_pro_i_buskey ON public.act_hi_procinst USING btree (business_key_);


--
-- Name: act_idx_hi_pro_inst_end; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_pro_inst_end ON public.act_hi_procinst USING btree (end_time_);


--
-- Name: act_idx_hi_pro_super_procinst; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_pro_super_procinst ON public.act_hi_procinst USING btree (super_process_instance_id_);


--
-- Name: act_idx_hi_procvar_exe; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_procvar_exe ON public.act_hi_varinst USING btree (execution_id_);


--
-- Name: act_idx_hi_procvar_name_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_procvar_name_type ON public.act_hi_varinst USING btree (name_, var_type_);


--
-- Name: act_idx_hi_procvar_proc_inst; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_procvar_proc_inst ON public.act_hi_varinst USING btree (proc_inst_id_);


--
-- Name: act_idx_hi_procvar_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_procvar_task_id ON public.act_hi_varinst USING btree (task_id_);


--
-- Name: act_idx_hi_task_inst_procinst; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_task_inst_procinst ON public.act_hi_taskinst USING btree (proc_inst_id_);


--
-- Name: act_idx_hi_task_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_task_scope ON public.act_hi_taskinst USING btree (scope_id_, scope_type_);


--
-- Name: act_idx_hi_task_scope_def; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_task_scope_def ON public.act_hi_taskinst USING btree (scope_definition_id_, scope_type_);


--
-- Name: act_idx_hi_task_sub_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_task_sub_scope ON public.act_hi_taskinst USING btree (sub_scope_id_, scope_type_);


--
-- Name: act_idx_hi_var_scope_id_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_var_scope_id_type ON public.act_hi_varinst USING btree (scope_id_, scope_type_);


--
-- Name: act_idx_hi_var_sub_id_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_hi_var_sub_id_type ON public.act_hi_varinst USING btree (sub_scope_id_, scope_type_);


--
-- Name: act_idx_ident_lnk_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ident_lnk_group ON public.act_ru_identitylink USING btree (group_id_);


--
-- Name: act_idx_ident_lnk_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ident_lnk_scope ON public.act_ru_identitylink USING btree (scope_id_, scope_type_);


--
-- Name: act_idx_ident_lnk_scope_def; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ident_lnk_scope_def ON public.act_ru_identitylink USING btree (scope_definition_id_, scope_type_);


--
-- Name: act_idx_ident_lnk_sub_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ident_lnk_sub_scope ON public.act_ru_identitylink USING btree (sub_scope_id_, scope_type_);


--
-- Name: act_idx_ident_lnk_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ident_lnk_user ON public.act_ru_identitylink USING btree (user_id_);


--
-- Name: act_idx_idl_procinst; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_idl_procinst ON public.act_ru_identitylink USING btree (proc_inst_id_);


--
-- Name: act_idx_job_correlation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_job_correlation_id ON public.act_ru_job USING btree (correlation_id_);


--
-- Name: act_idx_job_custom_values_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_job_custom_values_id ON public.act_ru_job USING btree (custom_values_id_);


--
-- Name: act_idx_job_exception_stack_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_job_exception_stack_id ON public.act_ru_job USING btree (exception_stack_id_);


--
-- Name: act_idx_job_execution_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_job_execution_id ON public.act_ru_job USING btree (execution_id_);


--
-- Name: act_idx_job_proc_def_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_job_proc_def_id ON public.act_ru_job USING btree (proc_def_id_);


--
-- Name: act_idx_job_process_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_job_process_instance_id ON public.act_ru_job USING btree (process_instance_id_);


--
-- Name: act_idx_job_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_job_scope ON public.act_ru_job USING btree (scope_id_, scope_type_);


--
-- Name: act_idx_job_scope_def; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_job_scope_def ON public.act_ru_job USING btree (scope_definition_id_, scope_type_);


--
-- Name: act_idx_job_sub_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_job_sub_scope ON public.act_ru_job USING btree (sub_scope_id_, scope_type_);


--
-- Name: act_idx_memb_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_memb_group ON public.act_id_membership USING btree (group_id_);


--
-- Name: act_idx_memb_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_memb_user ON public.act_id_membership USING btree (user_id_);


--
-- Name: act_idx_model_deployment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_model_deployment ON public.act_re_model USING btree (deployment_id_);


--
-- Name: act_idx_model_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_model_source ON public.act_re_model USING btree (editor_source_value_id_);


--
-- Name: act_idx_model_source_extra; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_model_source_extra ON public.act_re_model USING btree (editor_source_extra_value_id_);


--
-- Name: act_idx_priv_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_priv_group ON public.act_id_priv_mapping USING btree (group_id_);


--
-- Name: act_idx_priv_mapping; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_priv_mapping ON public.act_id_priv_mapping USING btree (priv_id_);


--
-- Name: act_idx_priv_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_priv_user ON public.act_id_priv_mapping USING btree (user_id_);


--
-- Name: act_idx_procdef_info_json; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_procdef_info_json ON public.act_procdef_info USING btree (info_json_id_);


--
-- Name: act_idx_procdef_info_proc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_procdef_info_proc ON public.act_procdef_info USING btree (proc_def_id_);


--
-- Name: act_idx_ru_acti_end; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ru_acti_end ON public.act_ru_actinst USING btree (end_time_);


--
-- Name: act_idx_ru_acti_exec; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ru_acti_exec ON public.act_ru_actinst USING btree (execution_id_);


--
-- Name: act_idx_ru_acti_exec_act; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ru_acti_exec_act ON public.act_ru_actinst USING btree (execution_id_, act_id_);


--
-- Name: act_idx_ru_acti_proc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ru_acti_proc ON public.act_ru_actinst USING btree (proc_inst_id_);


--
-- Name: act_idx_ru_acti_proc_act; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ru_acti_proc_act ON public.act_ru_actinst USING btree (proc_inst_id_, act_id_);


--
-- Name: act_idx_ru_acti_start; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ru_acti_start ON public.act_ru_actinst USING btree (start_time_);


--
-- Name: act_idx_ru_acti_task; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ru_acti_task ON public.act_ru_actinst USING btree (task_id_);


--
-- Name: act_idx_ru_var_scope_id_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ru_var_scope_id_type ON public.act_ru_variable USING btree (scope_id_, scope_type_);


--
-- Name: act_idx_ru_var_sub_id_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_ru_var_sub_id_type ON public.act_ru_variable USING btree (sub_scope_id_, scope_type_);


--
-- Name: act_idx_sjob_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_sjob_scope ON public.act_ru_suspended_job USING btree (scope_id_, scope_type_);


--
-- Name: act_idx_sjob_scope_def; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_sjob_scope_def ON public.act_ru_suspended_job USING btree (scope_definition_id_, scope_type_);


--
-- Name: act_idx_sjob_sub_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_sjob_sub_scope ON public.act_ru_suspended_job USING btree (sub_scope_id_, scope_type_);


--
-- Name: act_idx_suspended_job_correlation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_suspended_job_correlation_id ON public.act_ru_suspended_job USING btree (correlation_id_);


--
-- Name: act_idx_suspended_job_custom_values_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_suspended_job_custom_values_id ON public.act_ru_suspended_job USING btree (custom_values_id_);


--
-- Name: act_idx_suspended_job_exception_stack_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_suspended_job_exception_stack_id ON public.act_ru_suspended_job USING btree (exception_stack_id_);


--
-- Name: act_idx_suspended_job_execution_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_suspended_job_execution_id ON public.act_ru_suspended_job USING btree (execution_id_);


--
-- Name: act_idx_suspended_job_proc_def_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_suspended_job_proc_def_id ON public.act_ru_suspended_job USING btree (proc_def_id_);


--
-- Name: act_idx_suspended_job_process_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_suspended_job_process_instance_id ON public.act_ru_suspended_job USING btree (process_instance_id_);


--
-- Name: act_idx_task_create; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_task_create ON public.act_ru_task USING btree (create_time_);


--
-- Name: act_idx_task_exec; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_task_exec ON public.act_ru_task USING btree (execution_id_);


--
-- Name: act_idx_task_procdef; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_task_procdef ON public.act_ru_task USING btree (proc_def_id_);


--
-- Name: act_idx_task_procinst; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_task_procinst ON public.act_ru_task USING btree (proc_inst_id_);


--
-- Name: act_idx_task_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_task_scope ON public.act_ru_task USING btree (scope_id_, scope_type_);


--
-- Name: act_idx_task_scope_def; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_task_scope_def ON public.act_ru_task USING btree (scope_definition_id_, scope_type_);


--
-- Name: act_idx_task_sub_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_task_sub_scope ON public.act_ru_task USING btree (sub_scope_id_, scope_type_);


--
-- Name: act_idx_timer_job_correlation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_timer_job_correlation_id ON public.act_ru_timer_job USING btree (correlation_id_);


--
-- Name: act_idx_timer_job_custom_values_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_timer_job_custom_values_id ON public.act_ru_timer_job USING btree (custom_values_id_);


--
-- Name: act_idx_timer_job_duedate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_timer_job_duedate ON public.act_ru_timer_job USING btree (duedate_);


--
-- Name: act_idx_timer_job_exception_stack_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_timer_job_exception_stack_id ON public.act_ru_timer_job USING btree (exception_stack_id_);


--
-- Name: act_idx_timer_job_execution_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_timer_job_execution_id ON public.act_ru_timer_job USING btree (execution_id_);


--
-- Name: act_idx_timer_job_proc_def_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_timer_job_proc_def_id ON public.act_ru_timer_job USING btree (proc_def_id_);


--
-- Name: act_idx_timer_job_process_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_timer_job_process_instance_id ON public.act_ru_timer_job USING btree (process_instance_id_);


--
-- Name: act_idx_tjob_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_tjob_scope ON public.act_ru_timer_job USING btree (scope_id_, scope_type_);


--
-- Name: act_idx_tjob_scope_def; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_tjob_scope_def ON public.act_ru_timer_job USING btree (scope_definition_id_, scope_type_);


--
-- Name: act_idx_tjob_sub_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_tjob_sub_scope ON public.act_ru_timer_job USING btree (sub_scope_id_, scope_type_);


--
-- Name: act_idx_tskass_task; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_tskass_task ON public.act_ru_identitylink USING btree (task_id_);


--
-- Name: act_idx_var_bytearray; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_var_bytearray ON public.act_ru_variable USING btree (bytearray_id_);


--
-- Name: act_idx_var_exe; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_var_exe ON public.act_ru_variable USING btree (execution_id_);


--
-- Name: act_idx_var_procinst; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_var_procinst ON public.act_ru_variable USING btree (proc_inst_id_);


--
-- Name: act_idx_variable_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX act_idx_variable_task_id ON public.act_ru_variable USING btree (task_id_);


--
-- Name: flw_idx_batch_part; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX flw_idx_batch_part ON public.flw_ru_batch_part USING btree (batch_id_);


--
-- Name: flw_idx_event_rsrc_dpl; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX flw_idx_event_rsrc_dpl ON public.flw_event_resource USING btree (deployment_id_);


--
-- Name: idx_bill_log_bill; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bill_log_bill ON public.bill_log USING btree (bill_type, bill_id);


--
-- Name: idx_bill_relation_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bill_relation_source ON public.bill_relation USING btree (source_type, source_id);


--
-- Name: idx_bill_relation_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bill_relation_target ON public.bill_relation USING btree (target_type, target_id);


--
-- Name: idx_erp_customer_account_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_erp_customer_account_customer ON public.erp_customer_account USING btree (customer_id, id) WHERE (deleted = 0);


--
-- Name: idx_erp_customer_account_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_erp_customer_account_source ON public.erp_customer_account USING btree (source_type, source_id) WHERE ((deleted = 0) AND (source_id IS NOT NULL));


--
-- Name: idx_erp_customer_dept_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_erp_customer_dept_id ON public.erp_customer USING btree (dept_id);


--
-- Name: idx_erp_price_list_scope_partner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_erp_price_list_scope_partner ON public.erp_price_list_scope USING btree (partner_id);


--
-- Name: idx_erp_price_list_scope_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_erp_price_list_scope_price ON public.erp_price_list_scope USING btree (price_id);


--
-- Name: idx_erp_purchase_price_item_price_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_erp_purchase_price_item_price_id ON public.erp_price_list_item USING btree (price_id);


--
-- Name: idx_erp_purchase_price_item_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_erp_purchase_price_item_product ON public.erp_price_list_item USING btree (product_id);


--
-- Name: idx_erp_stock_batch_expiry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_erp_stock_batch_expiry ON public.erp_stock_batch USING btree (expiry_date) WHERE (deleted = 0);


--
-- Name: idx_erp_stock_batch_fifo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_erp_stock_batch_fifo ON public.erp_stock_batch USING btree (warehouse_id, product_id, in_date, expiry_date);


--
-- Name: idx_erp_stock_batch_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_erp_stock_batch_source ON public.erp_stock_batch USING btree (source_biz_type, source_biz_item_id) WHERE (deleted = 0);


--
-- Name: idx_erp_stock_batch_wh_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_erp_stock_batch_wh_product ON public.erp_stock_batch USING btree (warehouse_id, product_id, deleted);


--
-- Name: idx_infra_api_access_log_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_infra_api_access_log_01 ON public.infra_api_access_log USING btree (create_time);


--
-- Name: idx_infra_api_error_log_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_infra_api_error_log_01 ON public.infra_api_error_log USING btree (create_time);


--
-- Name: idx_infra_config_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_infra_config_01 ON public.infra_config USING btree (config_key);


--
-- Name: idx_infra_file_content_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_infra_file_content_01 ON public.infra_file_content USING btree (config_id, path);


--
-- Name: idx_infra_job_log_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_infra_job_log_01 ON public.infra_job_log USING btree (job_id);


--
-- Name: idx_infra_job_log_02; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_infra_job_log_02 ON public.infra_job_log USING btree (create_time);


--
-- Name: idx_member_user_store_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_member_user_store_user ON public.member_user_store USING btree (user_id) WHERE (deleted = 0);


--
-- Name: idx_price_item_log_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_price_item_log_price ON public.erp_price_list_item_log USING btree (price_id);


--
-- Name: idx_price_item_log_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_price_item_log_product ON public.erp_price_list_item_log USING btree (product_id);


--
-- Name: idx_qrtz_ft_inst_job_req_rcvry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_ft_inst_job_req_rcvry ON public.qrtz_fired_triggers USING btree (sched_name, instance_name, requests_recovery);


--
-- Name: idx_qrtz_ft_j_g; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_ft_j_g ON public.qrtz_fired_triggers USING btree (sched_name, job_name, job_group);


--
-- Name: idx_qrtz_ft_jg; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_ft_jg ON public.qrtz_fired_triggers USING btree (sched_name, job_group);


--
-- Name: idx_qrtz_ft_t_g; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_ft_t_g ON public.qrtz_fired_triggers USING btree (sched_name, trigger_name, trigger_group);


--
-- Name: idx_qrtz_ft_tg; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_ft_tg ON public.qrtz_fired_triggers USING btree (sched_name, trigger_group);


--
-- Name: idx_qrtz_ft_trig_inst_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_ft_trig_inst_name ON public.qrtz_fired_triggers USING btree (sched_name, instance_name);


--
-- Name: idx_qrtz_j_grp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_j_grp ON public.qrtz_job_details USING btree (sched_name, job_group);


--
-- Name: idx_qrtz_j_req_recovery; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_j_req_recovery ON public.qrtz_job_details USING btree (sched_name, requests_recovery);


--
-- Name: idx_qrtz_t_c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_t_c ON public.qrtz_triggers USING btree (sched_name, calendar_name);


--
-- Name: idx_qrtz_t_g; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_t_g ON public.qrtz_triggers USING btree (sched_name, trigger_group);


--
-- Name: idx_qrtz_t_j; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_t_j ON public.qrtz_triggers USING btree (sched_name, job_name, job_group);


--
-- Name: idx_qrtz_t_jg; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_t_jg ON public.qrtz_triggers USING btree (sched_name, job_group);


--
-- Name: idx_qrtz_t_n_g_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_t_n_g_state ON public.qrtz_triggers USING btree (sched_name, trigger_group, trigger_state);


--
-- Name: idx_qrtz_t_n_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_t_n_state ON public.qrtz_triggers USING btree (sched_name, trigger_name, trigger_group, trigger_state);


--
-- Name: idx_qrtz_t_next_fire_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_t_next_fire_time ON public.qrtz_triggers USING btree (sched_name, next_fire_time);


--
-- Name: idx_qrtz_t_nft_misfire; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_t_nft_misfire ON public.qrtz_triggers USING btree (sched_name, misfire_instr, next_fire_time);


--
-- Name: idx_qrtz_t_nft_st; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_t_nft_st ON public.qrtz_triggers USING btree (sched_name, trigger_state, next_fire_time);


--
-- Name: idx_qrtz_t_nft_st_misfire; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_t_nft_st_misfire ON public.qrtz_triggers USING btree (sched_name, misfire_instr, next_fire_time, trigger_state);


--
-- Name: idx_qrtz_t_nft_st_misfire_grp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_t_nft_st_misfire_grp ON public.qrtz_triggers USING btree (sched_name, misfire_instr, next_fire_time, trigger_group, trigger_state);


--
-- Name: idx_qrtz_t_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qrtz_t_state ON public.qrtz_triggers USING btree (sched_name, trigger_state);


--
-- Name: idx_system_dept_dept_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_dept_dept_type ON public.system_dept USING btree (dept_type) WHERE (deleted = 0);


--
-- Name: idx_system_login_log_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_login_log_01 ON public.system_login_log USING btree (username);


--
-- Name: idx_system_login_log_02; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_login_log_02 ON public.system_login_log USING btree (create_time);


--
-- Name: idx_system_notify_message_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_notify_message_01 ON public.system_notify_message USING btree (user_id, user_type, read_status);


--
-- Name: idx_system_oauth2_access_token_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_oauth2_access_token_01 ON public.system_oauth2_access_token USING btree (access_token);


--
-- Name: idx_system_oauth2_access_token_02; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_oauth2_access_token_02 ON public.system_oauth2_access_token USING btree (refresh_token);


--
-- Name: idx_system_oauth2_approve_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_oauth2_approve_01 ON public.system_oauth2_approve USING btree (user_id, user_type, client_id);


--
-- Name: idx_system_oauth2_client_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_oauth2_client_01 ON public.system_oauth2_client USING btree (client_id);


--
-- Name: idx_system_oauth2_code_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_oauth2_code_01 ON public.system_oauth2_code USING btree (code);


--
-- Name: idx_system_oauth2_refresh_token_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_oauth2_refresh_token_01 ON public.system_oauth2_refresh_token USING btree (refresh_token);


--
-- Name: idx_system_operate_log_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_operate_log_01 ON public.system_operate_log USING btree (user_id);


--
-- Name: idx_system_operate_log_02; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_operate_log_02 ON public.system_operate_log USING btree (create_time);


--
-- Name: idx_system_role_menu_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_role_menu_01 ON public.system_role_menu USING btree (role_id);


--
-- Name: idx_system_sms_code_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_sms_code_01 ON public.system_sms_code USING btree (mobile);


--
-- Name: idx_system_social_user_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_social_user_01 ON public.system_social_user USING btree (type, openid);


--
-- Name: idx_system_social_user_02; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_social_user_02 ON public.system_social_user USING btree (type, code, state);


--
-- Name: idx_system_social_user_bind_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_social_user_bind_01 ON public.system_social_user_bind USING btree (user_type, social_user_id);


--
-- Name: idx_system_user_role_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_user_role_01 ON public.system_user_role USING btree (user_id);


--
-- Name: idx_system_users_01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_users_01 ON public.system_users USING btree (username);


--
-- Name: idx_system_users_02; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_users_02 ON public.system_users USING btree (mobile);


--
-- Name: idx_system_users_03; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_users_03 ON public.system_users USING btree (email);


--
-- Name: idx_system_users_04; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_users_04 ON public.system_users USING btree (dept_id);


--
-- Name: idx_trade_order_audit_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trade_order_audit_status ON public.trade_order USING btree (audit_status);


--
-- Name: idx_trade_order_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trade_order_customer_id ON public.trade_order USING btree (customer_id);


--
-- Name: idx_trade_order_dept_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trade_order_dept_id ON public.trade_order USING btree (dept_id);


--
-- Name: idx_trade_order_item_alloc_mode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trade_order_item_alloc_mode ON public.trade_order_item USING btree (alloc_mode);


--
-- Name: idx_trade_order_payment_proof_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trade_order_payment_proof_order_id ON public.trade_order_payment_proof USING btree (order_id);


--
-- Name: idx_trade_order_receipt_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trade_order_receipt_customer ON public.trade_order_receipt USING btree (customer_id, status) WHERE (deleted = 0);


--
-- Name: idx_trade_order_receipt_item_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trade_order_receipt_item_product ON public.trade_order_receipt_item USING btree (product_id) WHERE (deleted = 0);


--
-- Name: idx_trade_order_receipt_item_receipt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trade_order_receipt_item_receipt ON public.trade_order_receipt_item USING btree (receipt_id) WHERE (deleted = 0);


--
-- Name: idx_trade_order_receipt_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trade_order_receipt_order ON public.trade_order_receipt USING btree (order_id) WHERE (deleted = 0);


--
-- Name: uk_bill_ext; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_bill_ext ON public.bill_ext USING btree (bill_type, bill_id, field_key, tenant_id) WHERE (deleted = 0);


--
-- Name: uk_bill_no_seq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_bill_no_seq ON public.bill_no_seq USING btree (bill_type, org_id, period, tenant_id) WHERE (deleted = 0);


--
-- Name: uk_bill_relation; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_bill_relation ON public.bill_relation USING btree (source_type, source_id, COALESCE(source_item_id, (0)::bigint), target_type, target_id, COALESCE(target_item_id, (0)::bigint), tenant_id) WHERE (deleted = 0);


--
-- Name: uk_bill_type_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_bill_type_code ON public.bill_type USING btree (code, tenant_id) WHERE (deleted = 0);


--
-- Name: uk_erp_customer_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_erp_customer_code ON public.erp_customer USING btree (tenant_id, code) WHERE ((deleted = 0) AND (code IS NOT NULL));


--
-- Name: uk_erp_customer_dept_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_erp_customer_dept_id ON public.erp_customer USING btree (dept_id) WHERE ((deleted = 0) AND (dept_id IS NOT NULL));


--
-- Name: uk_erp_product_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_erp_product_code ON public.erp_product USING btree (tenant_id, code) WHERE ((deleted = 0) AND (code IS NOT NULL));


--
-- Name: uk_erp_product_unit_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_erp_product_unit_code ON public.erp_product_unit USING btree (tenant_id, code) WHERE ((deleted = 0) AND (code IS NOT NULL));


--
-- Name: uk_erp_stock_batch; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_erp_stock_batch ON public.erp_stock_batch USING btree (warehouse_id, product_id, sku_id, batch_no, tenant_id) WHERE (deleted = 0);


--
-- Name: uk_erp_supplier_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_erp_supplier_code ON public.erp_supplier USING btree (tenant_id, code) WHERE ((deleted = 0) AND (code IS NOT NULL));


--
-- Name: uk_erp_warehouse_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_erp_warehouse_code ON public.erp_warehouse USING btree (tenant_id, code) WHERE ((deleted = 0) AND (code IS NOT NULL));


--
-- Name: uk_erp_warehouse_store_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_erp_warehouse_store_customer ON public.erp_warehouse USING btree (store_customer_id) WHERE ((deleted = 0) AND (store_customer_id IS NOT NULL));


--
-- Name: uk_member_user_store_user_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_member_user_store_user_customer ON public.member_user_store USING btree (user_id, customer_id) WHERE (deleted = 0);


--
-- Name: uk_member_user_store_user_default; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_member_user_store_user_default ON public.member_user_store USING btree (user_id) WHERE ((deleted = 0) AND (is_default = true));


--
-- Name: uk_member_user_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_member_user_username ON public.member_user USING btree (username) WHERE ((deleted = 0) AND (username IS NOT NULL));


--
-- Name: uk_price_list_scope_partner; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_price_list_scope_partner ON public.erp_price_list_scope USING btree (price_id, COALESCE(partner_id, (0)::bigint)) WHERE (deleted = 0);


--
-- Name: uk_product_sku_erp_product; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_product_sku_erp_product ON public.product_sku USING btree (erp_product_id) WHERE ((deleted = 0) AND (erp_product_id IS NOT NULL));


--
-- Name: uk_product_spu_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_product_spu_code ON public.product_spu USING btree (tenant_id, code) WHERE ((deleted = 0) AND (code IS NOT NULL));


--
-- Name: uk_system_code_rule_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_system_code_rule_key ON public.system_code_rule USING btree (tenant_id, rule_key) WHERE (deleted = 0);


--
-- Name: uk_system_dept_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_system_dept_code ON public.system_dept USING btree (tenant_id, code) WHERE ((deleted = 0) AND (code IS NOT NULL));


--
-- Name: uk_trade_order_receipt_item_order_item; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_trade_order_receipt_item_order_item ON public.trade_order_receipt_item USING btree (receipt_id, order_item_id) WHERE (deleted = 0);


--
-- Name: uk_trade_order_receipt_no; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_trade_order_receipt_no ON public.trade_order_receipt USING btree (no) WHERE (deleted = 0);


--
-- Name: uk_trade_order_receipt_sale_out; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_trade_order_receipt_sale_out ON public.trade_order_receipt USING btree (sale_out_id) WHERE ((deleted = 0) AND (sale_out_id IS NOT NULL) AND (status <> 20));


--
-- Name: act_ru_identitylink act_fk_athrz_procedef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_identitylink
    ADD CONSTRAINT act_fk_athrz_procedef FOREIGN KEY (proc_def_id_) REFERENCES public.act_re_procdef(id_);


--
-- Name: act_ge_bytearray act_fk_bytearr_depl; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ge_bytearray
    ADD CONSTRAINT act_fk_bytearr_depl FOREIGN KEY (deployment_id_) REFERENCES public.act_re_deployment(id_);


--
-- Name: act_ru_deadletter_job act_fk_deadletter_job_custom_values; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_deadletter_job
    ADD CONSTRAINT act_fk_deadletter_job_custom_values FOREIGN KEY (custom_values_id_) REFERENCES public.act_ge_bytearray(id_);


--
-- Name: act_ru_deadletter_job act_fk_deadletter_job_exception; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_deadletter_job
    ADD CONSTRAINT act_fk_deadletter_job_exception FOREIGN KEY (exception_stack_id_) REFERENCES public.act_ge_bytearray(id_);


--
-- Name: act_ru_deadletter_job act_fk_deadletter_job_execution; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_deadletter_job
    ADD CONSTRAINT act_fk_deadletter_job_execution FOREIGN KEY (execution_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_ru_deadletter_job act_fk_deadletter_job_proc_def; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_deadletter_job
    ADD CONSTRAINT act_fk_deadletter_job_proc_def FOREIGN KEY (proc_def_id_) REFERENCES public.act_re_procdef(id_);


--
-- Name: act_ru_deadletter_job act_fk_deadletter_job_process_instance; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_deadletter_job
    ADD CONSTRAINT act_fk_deadletter_job_process_instance FOREIGN KEY (process_instance_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_ru_event_subscr act_fk_event_exec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_event_subscr
    ADD CONSTRAINT act_fk_event_exec FOREIGN KEY (execution_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_ru_execution act_fk_exe_parent; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_execution
    ADD CONSTRAINT act_fk_exe_parent FOREIGN KEY (parent_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_ru_execution act_fk_exe_procdef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_execution
    ADD CONSTRAINT act_fk_exe_procdef FOREIGN KEY (proc_def_id_) REFERENCES public.act_re_procdef(id_);


--
-- Name: act_ru_execution act_fk_exe_procinst; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_execution
    ADD CONSTRAINT act_fk_exe_procinst FOREIGN KEY (proc_inst_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_ru_execution act_fk_exe_super; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_execution
    ADD CONSTRAINT act_fk_exe_super FOREIGN KEY (super_exec_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_ru_external_job act_fk_external_job_custom_values; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_external_job
    ADD CONSTRAINT act_fk_external_job_custom_values FOREIGN KEY (custom_values_id_) REFERENCES public.act_ge_bytearray(id_);


--
-- Name: act_ru_external_job act_fk_external_job_exception; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_external_job
    ADD CONSTRAINT act_fk_external_job_exception FOREIGN KEY (exception_stack_id_) REFERENCES public.act_ge_bytearray(id_);


--
-- Name: act_ru_identitylink act_fk_idl_procinst; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_identitylink
    ADD CONSTRAINT act_fk_idl_procinst FOREIGN KEY (proc_inst_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_procdef_info act_fk_info_json_ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_procdef_info
    ADD CONSTRAINT act_fk_info_json_ba FOREIGN KEY (info_json_id_) REFERENCES public.act_ge_bytearray(id_);


--
-- Name: act_procdef_info act_fk_info_procdef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_procdef_info
    ADD CONSTRAINT act_fk_info_procdef FOREIGN KEY (proc_def_id_) REFERENCES public.act_re_procdef(id_);


--
-- Name: act_ru_job act_fk_job_custom_values; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_job
    ADD CONSTRAINT act_fk_job_custom_values FOREIGN KEY (custom_values_id_) REFERENCES public.act_ge_bytearray(id_);


--
-- Name: act_ru_job act_fk_job_exception; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_job
    ADD CONSTRAINT act_fk_job_exception FOREIGN KEY (exception_stack_id_) REFERENCES public.act_ge_bytearray(id_);


--
-- Name: act_ru_job act_fk_job_execution; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_job
    ADD CONSTRAINT act_fk_job_execution FOREIGN KEY (execution_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_ru_job act_fk_job_proc_def; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_job
    ADD CONSTRAINT act_fk_job_proc_def FOREIGN KEY (proc_def_id_) REFERENCES public.act_re_procdef(id_);


--
-- Name: act_ru_job act_fk_job_process_instance; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_job
    ADD CONSTRAINT act_fk_job_process_instance FOREIGN KEY (process_instance_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_id_membership act_fk_memb_group; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_id_membership
    ADD CONSTRAINT act_fk_memb_group FOREIGN KEY (group_id_) REFERENCES public.act_id_group(id_);


--
-- Name: act_id_membership act_fk_memb_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_id_membership
    ADD CONSTRAINT act_fk_memb_user FOREIGN KEY (user_id_) REFERENCES public.act_id_user(id_);


--
-- Name: act_re_model act_fk_model_deployment; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_re_model
    ADD CONSTRAINT act_fk_model_deployment FOREIGN KEY (deployment_id_) REFERENCES public.act_re_deployment(id_);


--
-- Name: act_re_model act_fk_model_source; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_re_model
    ADD CONSTRAINT act_fk_model_source FOREIGN KEY (editor_source_value_id_) REFERENCES public.act_ge_bytearray(id_);


--
-- Name: act_re_model act_fk_model_source_extra; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_re_model
    ADD CONSTRAINT act_fk_model_source_extra FOREIGN KEY (editor_source_extra_value_id_) REFERENCES public.act_ge_bytearray(id_);


--
-- Name: act_id_priv_mapping act_fk_priv_mapping; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_id_priv_mapping
    ADD CONSTRAINT act_fk_priv_mapping FOREIGN KEY (priv_id_) REFERENCES public.act_id_priv(id_);


--
-- Name: act_ru_suspended_job act_fk_suspended_job_custom_values; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_suspended_job
    ADD CONSTRAINT act_fk_suspended_job_custom_values FOREIGN KEY (custom_values_id_) REFERENCES public.act_ge_bytearray(id_);


--
-- Name: act_ru_suspended_job act_fk_suspended_job_exception; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_suspended_job
    ADD CONSTRAINT act_fk_suspended_job_exception FOREIGN KEY (exception_stack_id_) REFERENCES public.act_ge_bytearray(id_);


--
-- Name: act_ru_suspended_job act_fk_suspended_job_execution; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_suspended_job
    ADD CONSTRAINT act_fk_suspended_job_execution FOREIGN KEY (execution_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_ru_suspended_job act_fk_suspended_job_proc_def; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_suspended_job
    ADD CONSTRAINT act_fk_suspended_job_proc_def FOREIGN KEY (proc_def_id_) REFERENCES public.act_re_procdef(id_);


--
-- Name: act_ru_suspended_job act_fk_suspended_job_process_instance; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_suspended_job
    ADD CONSTRAINT act_fk_suspended_job_process_instance FOREIGN KEY (process_instance_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_ru_task act_fk_task_exe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_task
    ADD CONSTRAINT act_fk_task_exe FOREIGN KEY (execution_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_ru_task act_fk_task_procdef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_task
    ADD CONSTRAINT act_fk_task_procdef FOREIGN KEY (proc_def_id_) REFERENCES public.act_re_procdef(id_);


--
-- Name: act_ru_task act_fk_task_procinst; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_task
    ADD CONSTRAINT act_fk_task_procinst FOREIGN KEY (proc_inst_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_ru_timer_job act_fk_timer_job_custom_values; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_timer_job
    ADD CONSTRAINT act_fk_timer_job_custom_values FOREIGN KEY (custom_values_id_) REFERENCES public.act_ge_bytearray(id_);


--
-- Name: act_ru_timer_job act_fk_timer_job_exception; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_timer_job
    ADD CONSTRAINT act_fk_timer_job_exception FOREIGN KEY (exception_stack_id_) REFERENCES public.act_ge_bytearray(id_);


--
-- Name: act_ru_timer_job act_fk_timer_job_execution; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_timer_job
    ADD CONSTRAINT act_fk_timer_job_execution FOREIGN KEY (execution_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_ru_timer_job act_fk_timer_job_proc_def; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_timer_job
    ADD CONSTRAINT act_fk_timer_job_proc_def FOREIGN KEY (proc_def_id_) REFERENCES public.act_re_procdef(id_);


--
-- Name: act_ru_timer_job act_fk_timer_job_process_instance; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_timer_job
    ADD CONSTRAINT act_fk_timer_job_process_instance FOREIGN KEY (process_instance_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_ru_identitylink act_fk_tskass_task; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_identitylink
    ADD CONSTRAINT act_fk_tskass_task FOREIGN KEY (task_id_) REFERENCES public.act_ru_task(id_);


--
-- Name: act_ru_variable act_fk_var_bytearray; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_variable
    ADD CONSTRAINT act_fk_var_bytearray FOREIGN KEY (bytearray_id_) REFERENCES public.act_ge_bytearray(id_);


--
-- Name: act_ru_variable act_fk_var_exe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_variable
    ADD CONSTRAINT act_fk_var_exe FOREIGN KEY (execution_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: act_ru_variable act_fk_var_procinst; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.act_ru_variable
    ADD CONSTRAINT act_fk_var_procinst FOREIGN KEY (proc_inst_id_) REFERENCES public.act_ru_execution(id_);


--
-- Name: flw_ru_batch_part flw_fk_batch_part_parent; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flw_ru_batch_part
    ADD CONSTRAINT flw_fk_batch_part_parent FOREIGN KEY (batch_id_) REFERENCES public.flw_ru_batch(id_);


--
-- Name: flw_event_resource flw_fk_event_rsrc_dpl; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flw_event_resource
    ADD CONSTRAINT flw_fk_event_rsrc_dpl FOREIGN KEY (deployment_id_) REFERENCES public.flw_event_deployment(id_);


--
-- Name: qrtz_blob_triggers qrtz_blob_triggers_sched_name_trigger_name_trigger_group_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_blob_triggers
    ADD CONSTRAINT qrtz_blob_triggers_sched_name_trigger_name_trigger_group_fkey FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES public.qrtz_triggers(sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_cron_triggers qrtz_cron_triggers_sched_name_trigger_name_trigger_group_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_cron_triggers
    ADD CONSTRAINT qrtz_cron_triggers_sched_name_trigger_name_trigger_group_fkey FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES public.qrtz_triggers(sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_simple_triggers qrtz_simple_triggers_sched_name_trigger_name_trigger_group_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_simple_triggers
    ADD CONSTRAINT qrtz_simple_triggers_sched_name_trigger_name_trigger_group_fkey FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES public.qrtz_triggers(sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_simprop_triggers qrtz_simprop_triggers_sched_name_trigger_name_trigger_grou_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_simprop_triggers
    ADD CONSTRAINT qrtz_simprop_triggers_sched_name_trigger_name_trigger_grou_fkey FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES public.qrtz_triggers(sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_triggers qrtz_triggers_sched_name_job_name_job_group_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_triggers
    ADD CONSTRAINT qrtz_triggers_sched_name_job_name_job_group_fkey FOREIGN KEY (sched_name, job_name, job_group) REFERENCES public.qrtz_job_details(sched_name, job_name, job_group);


--
-- PostgreSQL database dump complete
--

\unrestrict FJGYPIQk1taL7xtcr8JcvdWxTEiT6YBvMnkRfM5hH2D4xtOdH8eTgbxLea1oO5S

