--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgagent; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA pgagent;


ALTER SCHEMA pgagent OWNER TO postgres;

--
-- Name: SCHEMA pgagent; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA pgagent IS 'pgAgent system tables';


--
-- Name: pgagent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgagent WITH SCHEMA pgagent;


--
-- Name: EXTENSION pgagent; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgagent IS 'A PostgreSQL job scheduler';


--
-- Name: add_loyalty_points(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_loyalty_points() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.customer_id IS NOT NULL THEN
        UPDATE customers
        SET loyalty_points = loyalty_points + FLOOR(NEW.total_amount / 10)
        WHERE customer_id = NEW.customer_id;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_loyalty_points() OWNER TO postgres;

--
-- Name: calculate_subtotal(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_subtotal() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.subtotal := NEW.quantity * NEW.unit_price;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.calculate_subtotal() OWNER TO postgres;

--
-- Name: update_order_total(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_order_total() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE orders
    SET total_amount = (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM order_items
        WHERE order_id = NEW.order_id
    )
    WHERE order_id = NEW.order_id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_order_total() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    category_id integer NOT NULL,
    category_name character varying(50) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- Name: TABLE categories; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.categories IS 'Product categories';


--
-- Name: categories_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_category_id_seq OWNER TO postgres;

--
-- Name: categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categories_category_id_seq OWNED BY public.categories.category_id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customers (
    customer_id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    phone character varying(20) NOT NULL,
    email character varying(100),
    loyalty_points integer DEFAULT 0,
    registration_date date DEFAULT CURRENT_DATE NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT customers_loyalty_points_check CHECK ((loyalty_points >= 0))
);


ALTER TABLE public.customers OWNER TO postgres;

--
-- Name: TABLE customers; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.customers IS 'Customers with loyalty program';


--
-- Name: customers_customer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customers_customer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customers_customer_id_seq OWNER TO postgres;

--
-- Name: customers_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customers_customer_id_seq OWNED BY public.customers.customer_id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employees (
    employee_id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    phone character varying(20),
    email character varying(100),
    position_id integer NOT NULL,
    hire_date date DEFAULT CURRENT_DATE NOT NULL,
    salary numeric(10,2) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT employees_salary_check CHECK ((salary >= (0)::numeric))
);


ALTER TABLE public.employees OWNER TO postgres;

--
-- Name: TABLE employees; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.employees IS 'Employee information';


--
-- Name: employees_employee_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employees_employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employees_employee_id_seq OWNER TO postgres;

--
-- Name: employees_employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.employees_employee_id_seq OWNED BY public.employees.employee_id;


--
-- Name: ingredients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ingredients (
    ingredient_id integer NOT NULL,
    ingredient_name character varying(100) NOT NULL,
    unit character varying(20) NOT NULL,
    stock_quantity numeric(10,2) NOT NULL,
    min_quantity numeric(10,2) NOT NULL,
    cost_per_unit numeric(10,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ingredients_cost_per_unit_check CHECK ((cost_per_unit >= (0)::numeric)),
    CONSTRAINT ingredients_min_quantity_check CHECK ((min_quantity >= (0)::numeric)),
    CONSTRAINT ingredients_stock_quantity_check CHECK ((stock_quantity >= (0)::numeric))
);


ALTER TABLE public.ingredients OWNER TO postgres;

--
-- Name: TABLE ingredients; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.ingredients IS 'Ingredients for preparation';


--
-- Name: ingredients_ingredient_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ingredients_ingredient_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ingredients_ingredient_id_seq OWNER TO postgres;

--
-- Name: ingredients_ingredient_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ingredients_ingredient_id_seq OWNED BY public.ingredients.ingredient_id;


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_items (
    order_item_id integer NOT NULL,
    order_id integer NOT NULL,
    product_id integer NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    subtotal numeric(10,2) NOT NULL,
    customization text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT order_items_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT order_items_subtotal_check CHECK ((subtotal >= (0)::numeric)),
    CONSTRAINT order_items_unit_price_check CHECK ((unit_price >= (0)::numeric))
);


ALTER TABLE public.order_items OWNER TO postgres;

--
-- Name: TABLE order_items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.order_items IS 'Order line items';


--
-- Name: order_items_order_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_items_order_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_items_order_item_id_seq OWNER TO postgres;

--
-- Name: order_items_order_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_items_order_item_id_seq OWNED BY public.order_items.order_item_id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    order_id integer NOT NULL,
    user_id integer,
    customer_id integer,
    employee_id integer NOT NULL,
    order_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    total_amount numeric(10,2) NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    payment_method character varying(20) NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT orders_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['cash'::character varying, 'card'::character varying, 'online'::character varying])::text[]))),
    CONSTRAINT orders_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'preparing'::character varying, 'ready'::character varying, 'completed'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT orders_total_amount_check CHECK ((total_amount >= (0)::numeric))
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- Name: TABLE orders; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.orders IS 'Customer orders';


--
-- Name: orders_order_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orders_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.orders_order_id_seq OWNER TO postgres;

--
-- Name: orders_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orders_order_id_seq OWNED BY public.orders.order_id;


--
-- Name: positions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.positions (
    position_id integer NOT NULL,
    position_name character varying(50) NOT NULL,
    base_salary numeric(10,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positions_base_salary_check CHECK ((base_salary >= (0)::numeric))
);


ALTER TABLE public.positions OWNER TO postgres;

--
-- Name: TABLE positions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.positions IS 'Employee positions';


--
-- Name: positions_position_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.positions_position_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.positions_position_id_seq OWNER TO postgres;

--
-- Name: positions_position_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.positions_position_id_seq OWNED BY public.positions.position_id;


--
-- Name: product_ingredients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_ingredients (
    product_ingredient_id integer NOT NULL,
    product_id integer NOT NULL,
    ingredient_id integer NOT NULL,
    quantity numeric(10,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT product_ingredients_quantity_check CHECK ((quantity > (0)::numeric))
);


ALTER TABLE public.product_ingredients OWNER TO postgres;

--
-- Name: TABLE product_ingredients; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.product_ingredients IS 'Product composition';


--
-- Name: product_ingredients_product_ingredient_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_ingredients_product_ingredient_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_ingredients_product_ingredient_id_seq OWNER TO postgres;

--
-- Name: product_ingredients_product_ingredient_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_ingredients_product_ingredient_id_seq OWNED BY public.product_ingredients.product_ingredient_id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    product_id integer NOT NULL,
    product_name character varying(100) NOT NULL,
    category_id integer NOT NULL,
    price numeric(10,2) NOT NULL,
    description text,
    is_available boolean DEFAULT true,
    preparation_time integer,
    image_url character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT products_preparation_time_check CHECK ((preparation_time > 0)),
    CONSTRAINT products_price_check CHECK ((price > (0)::numeric))
);


ALTER TABLE public.products OWNER TO postgres;

--
-- Name: TABLE products; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.products IS 'Products and beverages';


--
-- Name: products_product_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.products_product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_product_id_seq OWNER TO postgres;

--
-- Name: products_product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.products_product_id_seq OWNED BY public.products.product_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    password_hash character varying(255) NOT NULL,
    full_name character varying(100),
    phone character varying(20),
    role character varying(20) DEFAULT 'user'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_login timestamp without time zone,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['admin'::character varying, 'manager'::character varying, 'user'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.users IS 'System users for authentication';


--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO postgres;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: v_daily_sales; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_daily_sales AS
 SELECT date(order_date) AS sale_date,
    count(*) AS total_orders,
    sum(total_amount) AS total_revenue,
    avg(total_amount) AS avg_order_value
   FROM public.orders
  WHERE ((status)::text = 'completed'::text)
  GROUP BY (date(order_date))
  ORDER BY (date(order_date)) DESC;


ALTER VIEW public.v_daily_sales OWNER TO postgres;

--
-- Name: v_popular_products; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_popular_products AS
 SELECT p.product_id,
    p.product_name,
    c.category_name,
    count(oi.order_item_id) AS times_ordered,
    sum(oi.quantity) AS total_quantity_sold,
    sum(oi.subtotal) AS total_revenue
   FROM (((public.products p
     JOIN public.categories c ON ((p.category_id = c.category_id)))
     LEFT JOIN public.order_items oi ON ((p.product_id = oi.product_id)))
     LEFT JOIN public.orders o ON (((oi.order_id = o.order_id) AND ((o.status)::text = 'completed'::text))))
  GROUP BY p.product_id, p.product_name, c.category_name
  ORDER BY (count(oi.order_item_id)) DESC;


ALTER VIEW public.v_popular_products OWNER TO postgres;

--
-- Name: v_products_full; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_products_full AS
 SELECT p.product_id,
    p.product_name,
    c.category_name,
    p.price,
    p.description,
    p.is_available,
    p.preparation_time
   FROM (public.products p
     JOIN public.categories c ON ((p.category_id = c.category_id)));


ALTER VIEW public.v_products_full OWNER TO postgres;

--
-- Name: categories category_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories ALTER COLUMN category_id SET DEFAULT nextval('public.categories_category_id_seq'::regclass);


--
-- Name: customers customer_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers ALTER COLUMN customer_id SET DEFAULT nextval('public.customers_customer_id_seq'::regclass);


--
-- Name: employees employee_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees ALTER COLUMN employee_id SET DEFAULT nextval('public.employees_employee_id_seq'::regclass);


--
-- Name: ingredients ingredient_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ingredients ALTER COLUMN ingredient_id SET DEFAULT nextval('public.ingredients_ingredient_id_seq'::regclass);


--
-- Name: order_items order_item_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items ALTER COLUMN order_item_id SET DEFAULT nextval('public.order_items_order_item_id_seq'::regclass);


--
-- Name: orders order_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders ALTER COLUMN order_id SET DEFAULT nextval('public.orders_order_id_seq'::regclass);


--
-- Name: positions position_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions ALTER COLUMN position_id SET DEFAULT nextval('public.positions_position_id_seq'::regclass);


--
-- Name: product_ingredients product_ingredient_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_ingredients ALTER COLUMN product_ingredient_id SET DEFAULT nextval('public.product_ingredients_product_ingredient_id_seq'::regclass);


--
-- Name: products product_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products ALTER COLUMN product_id SET DEFAULT nextval('public.products_product_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Data for Name: pga_jobagent; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobagent (jagpid, jaglogintime, jagstation) FROM stdin;
\.


--
-- Data for Name: pga_jobclass; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobclass (jclid, jclname) FROM stdin;
\.


--
-- Data for Name: pga_job; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_job (jobid, jobjclid, jobname, jobdesc, jobhostagent, jobenabled, jobcreated, jobchanged, jobagentid, jobnextrun, joblastrun) FROM stdin;
2	1	BubbleTea Daily Logical Backup	Daily logical backup (pg_dump) of BibaBobaBebe database at 2:00 AM. Retention: 30 days.		t	2025-11-02 21:06:04.765281+05	2025-11-02 21:06:04.765281+05	\N	2025-11-03 02:00:00+05	\N
3	1	BubbleTea Weekly Physical Backup	Weekly physical backup (pg_basebackup) every Sunday at 3:00 AM. Retention: 7 days.		t	2025-11-02 21:06:04.765281+05	2025-11-02 21:06:04.765281+05	\N	2025-11-09 03:00:00+05	\N
\.


--
-- Data for Name: pga_schedule; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_schedule (jscid, jscjobid, jscname, jscdesc, jscenabled, jscstart, jscend, jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths) FROM stdin;
1	2	Daily at 2:00 AM		t	2025-11-02 21:06:04.765281+05	\N	{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}	{f,f,t,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}	{t,t,t,t,t,t,t}	{t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t}	{t,t,t,t,t,t,t,t,t,t,t,t}
2	3	Weekly Sunday at 3:00 AM		t	2025-11-02 21:06:04.765281+05	\N	{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}	{f,f,f,t,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}	{t,f,f,f,f,f,f}	{t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t}	{t,t,t,t,t,t,t,t,t,t,t,t}
\.


--
-- Data for Name: pga_exception; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_exception (jexid, jexscid, jexdate, jextime) FROM stdin;
\.


--
-- Data for Name: pga_joblog; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_joblog (jlgid, jlgjobid, jlgstatus, jlgstart, jlgduration) FROM stdin;
\.


--
-- Data for Name: pga_jobstep; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobstep (jstid, jstjobid, jstname, jstdesc, jstenabled, jstkind, jstcode, jstconnstr, jstdbname, jstonerror, jscnextrun) FROM stdin;
1	2	Execute pg_dump backup script		t	b	cd /d "D:\\POProject\\Bubble Tea\\database\\backup_scripts" && pg_dump_backup.bat			f	\N
2	3	Execute pg_basebackup script		t	b	cd /d "D:\\POProject\\Bubble Tea\\database\\backup_scripts" && pg_basebackup.bat			f	\N
\.


--
-- Data for Name: pga_jobsteplog; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobsteplog (jslid, jsljlgid, jsljstid, jslstatus, jslresult, jslstart, jslduration, jsloutput) FROM stdin;
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categories (category_id, category_name, description, created_at) FROM stdin;
1	Bubble Tea	Classic tea with boba pearls (tapioca)	2025-11-02 20:37:54.33073
2	Fruit Tea	Refreshing fruit beverages	2025-11-02 20:37:54.33073
3	Coffee Drinks	Coffee and coffee cocktails	2025-11-02 20:37:54.33073
4	Smoothies	Fruit and berry smoothies	2025-11-02 20:37:54.33073
5	Desserts	Pastries and sweets	2025-11-02 20:37:54.33073
6	Snacks	Snacks and light bites	2025-11-02 20:37:54.33073
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customers (customer_id, first_name, last_name, phone, email, loyalty_points, registration_date, created_at) FROM stdin;
1	Olga	Volkova	+7-911-111-1111	olga.volkova@email.ru	150	2024-01-10	2025-11-02 20:37:54.328344
2	Sergey	Novikov	+7-911-222-2222	sergey.novikov@email.ru	230	2024-01-15	2025-11-02 20:37:54.328344
3	Natalia	Fedorova	+7-911-333-3333	natalia.fedorova@email.ru	89	2024-02-01	2025-11-02 20:37:54.328344
4	Mikhail	Lebedev	+7-911-444-4444	mikhail.lebedev@email.ru	456	2024-02-10	2025-11-02 20:37:54.328344
5	Tatiana	Sokolova	+7-911-555-5555	tatiana.sokolova@email.ru	78	2024-03-05	2025-11-02 20:37:54.328344
6	Andrey	Popov	+7-911-666-6666	andrey.popov@email.ru	312	2024-03-15	2025-11-02 20:37:54.328344
7	Ekaterina	Kozlova	+7-911-777-7777	ekaterina.kozlova@email.ru	199	2024-04-01	2025-11-02 20:37:54.328344
8	Vladimir	Vasiliev	+7-911-888-8888	vladimir.vasiliev@email.ru	567	2024-04-10	2025-11-02 20:37:54.328344
9	Administrator		None	\N	0	2025-11-05	2025-11-05 21:42:55.303504
\.


--
-- Data for Name: employees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employees (employee_id, first_name, last_name, phone, email, position_id, hire_date, salary, is_active, created_at) FROM stdin;
1	Alex	Ivanov	+7-900-123-4567	alex.ivanov@bibabobabebe.ru	5	2023-01-15	100000.00	t	2025-11-02 20:37:54.325515
2	Maria	Petrova	+7-900-234-5678	maria.petrova@bibabobabebe.ru	4	2023-02-01	75000.00	t	2025-11-02 20:37:54.325515
3	Dmitry	Sidorov	+7-900-345-6789	dmitry.sidorov@bibabobabebe.ru	3	2023-03-10	65000.00	t	2025-11-02 20:37:54.325515
4	Anna	Kuznetsova	+7-900-456-7890	anna.kuznetsova@bibabobabebe.ru	2	2023-04-05	55000.00	t	2025-11-02 20:37:54.325515
5	Elena	Smirnova	+7-900-567-8901	elena.smirnova@bibabobabebe.ru	1	2023-05-20	40000.00	t	2025-11-02 20:37:54.325515
6	Ivan	Morozov	+7-900-678-9012	ivan.morozov@bibabobabebe.ru	1	2023-06-15	40000.00	t	2025-11-02 20:37:54.325515
\.


--
-- Data for Name: ingredients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ingredients (ingredient_id, ingredient_name, unit, stock_quantity, min_quantity, cost_per_unit, created_at) FROM stdin;
2	Green Tea	g	3000.00	300.00	0.80	2025-11-02 20:37:54.334564
5	Taro Syrup	ml	3000.00	500.00	0.50	2025-11-02 20:37:54.334564
6	Matcha Powder	g	1000.00	100.00	3.00	2025-11-02 20:37:54.334564
7	Chocolate Syrup	ml	4000.00	500.00	0.40	2025-11-02 20:37:54.334564
8	Mango Puree	ml	5000.00	1000.00	0.60	2025-11-02 20:37:54.334564
9	Frozen Strawberry	g	8000.00	1000.00	0.30	2025-11-02 20:37:54.334564
10	Passion Fruit Puree	ml	3000.00	500.00	0.80	2025-11-02 20:37:54.334564
11	Arabica Coffee Beans	g	15000.00	2000.00	0.70	2025-11-02 20:37:54.334564
12	Caramel Syrup	ml	3000.00	500.00	0.35	2025-11-02 20:37:54.334564
13	Cream 33%	ml	10000.00	1000.00	0.15	2025-11-02 20:37:54.334564
14	Banana	pcs	100.00	20.00	30.00	2025-11-02 20:37:54.334564
15	Wild Berry Mix	g	5000.00	1000.00	0.50	2025-11-02 20:37:54.334564
1	Black Tea (leaf)	g	4980.00	500.00	0.50	2025-11-02 20:37:54.334564
3	Milk 3.2%	ml	49600.00	5000.00	0.08	2025-11-02 20:37:54.334564
4	Tapioca (boba)	g	9900.00	1000.00	0.15	2025-11-02 20:37:54.334564
16	Sugar	g	19970.00	2000.00	0.05	2025-11-02 20:37:54.334564
17	Ice	g	49800.00	5000.00	0.01	2025-11-02 20:37:54.334564
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_items (order_item_id, order_id, product_id, quantity, unit_price, subtotal, customization, created_at) FROM stdin;
1	1	1	2	350.00	700.00	\N	2025-11-02 20:37:54.342345
2	1	13	1	250.00	250.00	\N	2025-11-02 20:37:54.342345
3	2	3	1	420.00	420.00	\N	2025-11-02 20:37:54.342345
4	2	14	2	180.00	360.00	\N	2025-11-02 20:37:54.342345
5	3	5	1	340.00	340.00	\N	2025-11-02 20:37:54.342345
6	3	6	1	360.00	360.00	\N	2025-11-02 20:37:54.342345
7	4	2	1	380.00	380.00	No sugar	2025-11-02 20:37:54.342345
8	4	8	1	280.00	280.00	\N	2025-11-02 20:37:54.342345
9	5	9	2	290.00	580.00	\N	2025-11-02 20:37:54.342345
10	5	15	1	220.00	220.00	\N	2025-11-02 20:37:54.342345
11	6	4	1	390.00	390.00	\N	2025-11-02 20:37:54.342345
12	6	13	1	250.00	250.00	\N	2025-11-02 20:37:54.342345
13	6	16	1	150.00	150.00	\N	2025-11-02 20:37:54.342345
14	7	7	1	370.00	370.00	\N	2025-11-02 20:37:54.342345
15	7	11	1	320.00	320.00	\N	2025-11-02 20:37:54.342345
16	8	1	1	350.00	350.00	\N	2025-11-02 20:37:54.342345
17	8	10	2	330.00	660.00	\N	2025-11-02 20:37:54.342345
18	9	12	1	300.00	300.00	\N	2025-11-02 20:37:54.342345
19	9	14	1	180.00	180.00	\N	2025-11-02 20:37:54.342345
20	10	3	2	420.00	840.00	\N	2025-11-02 20:37:54.342345
21	11	5	1	340.00	340.00	\N	2025-11-02 20:37:54.342345
22	11	15	2	220.00	440.00	\N	2025-11-02 20:37:54.342345
23	12	2	1	380.00	380.00	\N	2025-11-02 20:37:54.342345
24	13	1	1	5.50	5.50	\N	2025-11-05 21:42:55.6775
25	14	1	1	5.50	5.50	\N	2025-11-05 23:26:25.644602
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orders (order_id, user_id, customer_id, employee_id, order_date, total_amount, status, payment_method, notes, created_at) FROM stdin;
1	\N	1	5	2024-10-01 10:30:00	950.00	completed	card	\N	2025-11-02 20:37:54.339185
2	\N	2	6	2024-10-01 11:15:00	780.00	completed	cash	\N	2025-11-02 20:37:54.339185
3	\N	3	5	2024-10-01 12:45:00	700.00	completed	card	\N	2025-11-02 20:37:54.339185
4	\N	4	6	2024-10-02 09:20:00	660.00	completed	online	No sugar	2025-11-02 20:37:54.339185
5	\N	5	5	2024-10-02 14:30:00	800.00	completed	card	\N	2025-11-02 20:37:54.339185
6	\N	6	6	2024-10-03 10:00:00	790.00	completed	cash	\N	2025-11-02 20:37:54.339185
7	\N	7	5	2024-10-03 15:45:00	690.00	completed	card	\N	2025-11-02 20:37:54.339185
8	\N	8	6	2024-10-04 11:30:00	1010.00	completed	online	\N	2025-11-02 20:37:54.339185
9	\N	1	5	2024-10-05 13:00:00	480.00	completed	card	\N	2025-11-02 20:37:54.339185
10	\N	2	6	2024-10-05 16:20:00	840.00	completed	cash	\N	2025-11-02 20:37:54.339185
11	\N	3	5	2024-10-06 10:45:00	780.00	preparing	card	\N	2025-11-02 20:37:54.339185
12	\N	4	6	2024-10-06 12:15:00	380.00	pending	cash	\N	2025-11-02 20:37:54.339185
13	1	9	1	2025-11-05 21:42:55.541498	5.50	completed	cash		2025-11-05 21:42:55.541498
14	1	9	1	2025-11-05 23:26:25.588627	5.50	pending	cash		2025-11-05 23:26:25.588627
\.


--
-- Data for Name: positions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.positions (position_id, position_name, base_salary, created_at) FROM stdin;
1	Barista	40000.00	2025-11-02 20:37:54.322299
2	Senior Barista	55000.00	2025-11-02 20:37:54.322299
3	Shift Manager	65000.00	2025-11-02 20:37:54.322299
4	Administrator	75000.00	2025-11-02 20:37:54.322299
5	Director	100000.00	2025-11-02 20:37:54.322299
\.


--
-- Data for Name: product_ingredients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_ingredients (product_ingredient_id, product_id, ingredient_id, quantity, created_at) FROM stdin;
1	1	1	10.00	2025-11-02 20:37:54.336414
2	1	3	200.00	2025-11-02 20:37:54.336414
3	1	4	50.00	2025-11-02 20:37:54.336414
4	1	16	15.00	2025-11-02 20:37:54.336414
5	1	17	100.00	2025-11-02 20:37:54.336414
6	2	1	10.00	2025-11-02 20:37:54.336414
7	2	3	180.00	2025-11-02 20:37:54.336414
8	2	4	50.00	2025-11-02 20:37:54.336414
9	2	5	30.00	2025-11-02 20:37:54.336414
10	2	17	100.00	2025-11-02 20:37:54.336414
11	3	6	5.00	2025-11-02 20:37:54.336414
12	3	3	250.00	2025-11-02 20:37:54.336414
13	3	4	50.00	2025-11-02 20:37:54.336414
14	3	16	10.00	2025-11-02 20:37:54.336414
15	3	17	50.00	2025-11-02 20:37:54.336414
16	4	3	200.00	2025-11-02 20:37:54.336414
17	4	4	50.00	2025-11-02 20:37:54.336414
18	4	7	40.00	2025-11-02 20:37:54.336414
19	4	17	100.00	2025-11-02 20:37:54.336414
20	5	2	8.00	2025-11-02 20:37:54.336414
21	5	8	80.00	2025-11-02 20:37:54.336414
22	5	16	10.00	2025-11-02 20:37:54.336414
23	5	17	150.00	2025-11-02 20:37:54.336414
24	6	2	8.00	2025-11-02 20:37:54.336414
25	6	9	100.00	2025-11-02 20:37:54.336414
26	6	16	15.00	2025-11-02 20:37:54.336414
27	6	17	150.00	2025-11-02 20:37:54.336414
28	7	2	8.00	2025-11-02 20:37:54.336414
29	7	10	70.00	2025-11-02 20:37:54.336414
30	7	16	12.00	2025-11-02 20:37:54.336414
31	7	17	150.00	2025-11-02 20:37:54.336414
32	8	11	18.00	2025-11-02 20:37:54.336414
33	8	3	150.00	2025-11-02 20:37:54.336414
34	9	11	18.00	2025-11-02 20:37:54.336414
35	9	3	200.00	2025-11-02 20:37:54.336414
36	10	11	18.00	2025-11-02 20:37:54.336414
37	10	13	100.00	2025-11-02 20:37:54.336414
38	10	12	30.00	2025-11-02 20:37:54.336414
39	11	15	200.00	2025-11-02 20:37:54.336414
40	11	3	100.00	2025-11-02 20:37:54.336414
41	11	16	10.00	2025-11-02 20:37:54.336414
42	11	17	50.00	2025-11-02 20:37:54.336414
43	12	14	1.50	2025-11-02 20:37:54.336414
44	12	3	150.00	2025-11-02 20:37:54.336414
45	12	16	10.00	2025-11-02 20:37:54.336414
46	12	17	50.00	2025-11-02 20:37:54.336414
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.products (product_id, product_name, category_id, price, description, is_available, preparation_time, image_url, created_at) FROM stdin;
12	Banana Paradise	4	5.95	Smoothie with banana and milk	t	3	/static/images/products/20251106151902_20251106110608_Banana-Milkshake-5-1.jpg	2025-11-02 20:37:54.332478
11	Berry Mix	4	6.25	Wild berry smoothie	t	3	/static/images/products/20251106151917_20251106110647_BerryMilkshake-Feb-1.jpg	2025-11-02 20:37:54.332478
8	Cappuccino	3	4.50	Classic Italian cappuccino	t	4	/static/images/products/20251106151924_20251106110821_how-to-make-cappuccinos-766116-hero-01-a754d567739b4ee0b209305138ecb996.jpg	2025-11-02 20:37:54.332478
16	Caramel Popcorn	6	3.50	Sweet caramel popcorn	t	2	/static/images/products/20251106151931_20251106110902_miso-caramel-popcorn-caramel-corn-the-heirloom-pantry-05.jpg	2025-11-02 20:37:54.332478
10	Caramel Raf	3	5.50	Raf coffee with caramel syrup	t	5	/static/images/products/20251106151941_20251106110934_zagotovka-karamel-1-min.jpg	2025-11-02 20:37:54.332478
13	Cheesecake	5	4.95	Classic New York style cheesecake	t	2	/static/images/products/20251106151946_20251106110959_cheesecake-1200x1393.webp	2025-11-02 20:37:54.332478
4	Chocolate Boba	1	6.25	Chocolate drink with tapioca pearls	t	5	/static/images/products/20251106151951_20251106111034_IMG_1811.jpg	2025-11-02 20:37:54.332478
14	Chocolate Muffin	5	3.25	Moist chocolate chip muffin	t	1	/static/images/products/20251106151957_20251106111105_chocolate-muffin-with-plum-jam-best-of-hungary_d9ba5c99-a6aa-4400-8437-32c7d1a890a0.jpg	2025-11-02 20:37:54.332478
1	Classic Milk Tea	1	5.50	Black tea with milk and tapioca pearls	t	5	/static/images/products/20251106152003_20251106111144_bubble_tea_recipe_062817.webp	2025-11-02 20:37:54.332478
9	Latte	3	4.75	Smooth coffee latte	t	4	/static/images/products/20251106152010_20251106111211_Latte_0_7.webp	2025-11-02 20:37:54.332478
15	Macarons (3 pcs)	5	4.50	French macarons, assorted flavors, 3 pieces	t	1	/static/images/products/20251106152019_20251106111319_1704989044_50591525.jpg	2025-11-02 20:37:54.332478
5	Mango Fresh	2	5.25	Refreshing tea with fresh mango	t	4	/static/images/products/20251106152032_20251106111359_Mango_Bubble_Tea_Powder_Bubble_Tea_Supplies_United_Kingdom__18305.jpg	2025-11-02 20:37:54.332478
3	Matcha Latte with Boba	1	6.50	Green matcha tea with milk and tapioca pearls	t	6	/static/images/products/20251106152049_20251106111441_matcha-boba-tea-5.jpg	2025-11-02 20:37:54.332478
7	Passion Fruit Tropic	2	5.95	Tropical tea with passion fruit	t	4	/static/images/products/20251106152059_20251106111522_passion_fruit.jpg	2025-11-02 20:37:54.332478
6	Strawberry Blast	2	5.75	Tea with strawberry and fruit pieces	t	4	/static/images/products/20251106152106_20251106111801_Strawberry-Milk-Tea-Boba-11.jpg	2025-11-02 20:37:54.332478
2	Taro Milk Tea	1	5.95	Tea with taro and tapioca pearls	t	5	/static/images/products/20251106152129_20251106111834_136A0988-735x1103.webp	2025-11-02 20:37:54.332478
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, username, email, password_hash, full_name, phone, role, is_active, created_at, last_login) FROM stdin;
1	admin	admin@bibabobabebe.com	scrypt:32768:8:1$I9vMTm5e1vieLoqa$e0c89ce27c14b958cb9fa37db7363526f508c9394cf195cbbde9d8550a57e2a6164a3f185d08872476545671552614a4d53bab0edf2902a8ab80477788bbb7d5	Administrator	\N	admin	t	2025-11-02 20:38:22.693234	2026-02-17 19:49:10.481937
\.


--
-- Name: categories_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_category_id_seq', 6, true);


--
-- Name: customers_customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customers_customer_id_seq', 9, true);


--
-- Name: employees_employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employees_employee_id_seq', 6, true);


--
-- Name: ingredients_ingredient_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ingredients_ingredient_id_seq', 17, true);


--
-- Name: order_items_order_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_items_order_item_id_seq', 25, true);


--
-- Name: orders_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orders_order_id_seq', 14, true);


--
-- Name: positions_position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.positions_position_id_seq', 5, true);


--
-- Name: product_ingredients_product_ingredient_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_ingredients_product_ingredient_id_seq', 46, true);


--
-- Name: products_product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.products_product_id_seq', 16, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_user_id_seq', 1, true);


--
-- Name: categories categories_category_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_category_name_key UNIQUE (category_name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);


--
-- Name: customers customers_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_email_key UNIQUE (email);


--
-- Name: customers customers_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_phone_key UNIQUE (phone);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- Name: employees employees_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_email_key UNIQUE (email);


--
-- Name: employees employees_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_phone_key UNIQUE (phone);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (employee_id);


--
-- Name: ingredients ingredients_ingredient_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_ingredient_name_key UNIQUE (ingredient_name);


--
-- Name: ingredients ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_pkey PRIMARY KEY (ingredient_id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (order_item_id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (order_id);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (position_id);


--
-- Name: positions positions_position_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_position_name_key UNIQUE (position_name);


--
-- Name: product_ingredients product_ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_ingredients
    ADD CONSTRAINT product_ingredients_pkey PRIMARY KEY (product_ingredient_id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- Name: product_ingredients unique_product_ingredient; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_ingredients
    ADD CONSTRAINT unique_product_ingredient UNIQUE (product_id, ingredient_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_employees_position; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_employees_position ON public.employees USING btree (position_id);


--
-- Name: idx_order_items_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_items_order ON public.order_items USING btree (order_id);


--
-- Name: idx_order_items_product; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_items_product ON public.order_items USING btree (product_id);


--
-- Name: idx_orders_customer; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_customer ON public.orders USING btree (customer_id);


--
-- Name: idx_orders_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_date ON public.orders USING btree (order_date);


--
-- Name: idx_orders_employee; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_employee ON public.orders USING btree (employee_id);


--
-- Name: idx_orders_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_status ON public.orders USING btree (status);


--
-- Name: idx_products_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_products_category ON public.products USING btree (category_id);


--
-- Name: orders trg_add_loyalty_points; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_add_loyalty_points AFTER UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.add_loyalty_points();


--
-- Name: order_items trg_calculate_subtotal; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_calculate_subtotal BEFORE INSERT OR UPDATE ON public.order_items FOR EACH ROW EXECUTE FUNCTION public.calculate_subtotal();


--
-- Name: order_items trg_update_order_total_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_order_total_insert AFTER INSERT ON public.order_items FOR EACH ROW EXECUTE FUNCTION public.update_order_total();


--
-- Name: order_items trg_update_order_total_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_order_total_update AFTER UPDATE ON public.order_items FOR EACH ROW EXECUTE FUNCTION public.update_order_total();


--
-- Name: employees fk_employee_position; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_employee_position FOREIGN KEY (position_id) REFERENCES public.positions(position_id) ON DELETE RESTRICT;


--
-- Name: order_items fk_oi_order; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT fk_oi_order FOREIGN KEY (order_id) REFERENCES public.orders(order_id) ON DELETE CASCADE;


--
-- Name: order_items fk_oi_product; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT fk_oi_product FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE RESTRICT;


--
-- Name: orders fk_order_customer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id) ON DELETE SET NULL;


--
-- Name: orders fk_order_employee; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_order_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id) ON DELETE RESTRICT;


--
-- Name: orders fk_order_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_order_user FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: product_ingredients fk_pi_ingredient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_ingredients
    ADD CONSTRAINT fk_pi_ingredient FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(ingredient_id) ON DELETE RESTRICT;


--
-- Name: product_ingredients fk_pi_product; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_ingredients
    ADD CONSTRAINT fk_pi_product FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: products fk_product_category; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT fk_product_category FOREIGN KEY (category_id) REFERENCES public.categories(category_id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

