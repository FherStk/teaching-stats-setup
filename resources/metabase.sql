--
-- PostgreSQL database dump
--

-- Dumped from database version 12.9 (Ubuntu 12.9-0ubuntu0.20.04.1)
-- Dumped by pg_dump version 12.9 (Ubuntu 12.9-0ubuntu0.20.04.1)

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

SET default_tablespace = '';
SET default_table_access_method = heap;

--
-- Data for Name: collection; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.collection (id, name, description, color, archived, location, personal_owner_id, slug, namespace) FROM stdin;
2	Fer Porrino Serrano's Personal Collection	\N	#31698A	f	/	2	fer_porrino_serrano_s_personal_collection	\N
1	Marcos Alcocer Gil's Personal Collection	\N	#31698A	f	/	1	marcos_alcocer_gil_s_personal_collection	\N
3	Centre	\N	#509EE3	f	/	\N	centre	\N
4	CF - Tutoria	\N	#509EE3	f	/	\N	cf___tutoria	\N
5	CF - MP	\N	#509EE3	f	/	\N	cf___mp	\N
6	CF - Dept. Administració i gestió	\N	#509EE3	f	/	\N	cf___dept__administracio_i_gestio	\N
7	CF - Dept. Informàtica i comunicacions	\N	#509EE3	f	/	\N	cf___dept__informatica_i_comunicacions	\N
\.

