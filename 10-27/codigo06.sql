-- Active: 1793145257283@@127.0.0.1@5432@bd_plano_saude@public
DROP TABLE IF EXISTS planilha_atendimento;
DROP VIEW  IF EXISTS vw_dependente;
DROP VIEW  IF EXISTS vw_consulta;
DROP TABLE IF EXISTS exame_solicitado;
DROP TABLE IF EXISTS consulta;
DROP TABLE IF EXISTS credenciamento;
DROP TABLE IF EXISTS telefone;
DROP TABLE IF EXISTS medico;
DROP TABLE IF EXISTS paciente;
DROP TABLE IF EXISTS especialidade;
DROP TABLE IF EXISTS convenio;
DROP TABLE IF EXISTS pessoa;

CREATE TABLE pessoa (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome            TEXT    NOT NULL,
    cpf             TEXT    NOT NULL UNIQUE,
    data_nascimento DATE    NOT NULL,
    logradouro      TEXT    NOT NULL,
    numero          TEXT    NOT NULL,
    bairro          TEXT    NOT NULL,
    cidade          TEXT    NOT NULL
);

CREATE TABLE telefone (
    pessoa_id INTEGER NOT NULL REFERENCES pessoa (id),
    numero    TEXT    NOT NULL,
    PRIMARY KEY (pessoa_id, numero)
);

CREATE TABLE especialidade (
    id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome TEXT    NOT NULL UNIQUE
);

CREATE TABLE convenio (
    id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome TEXT    NOT NULL UNIQUE
);

CREATE TABLE paciente (
    pessoa_id     INTEGER PRIMARY KEY REFERENCES pessoa (id),
    data_cadastro DATE    NOT NULL,
    titular_id    INTEGER REFERENCES paciente (pessoa_id)
);

CREATE TABLE medico (
    pessoa_id        INTEGER PRIMARY KEY REFERENCES pessoa (id),
    crm              TEXT    NOT NULL UNIQUE,
    especialidade_id INTEGER NOT NULL REFERENCES especialidade (id)
);

CREATE TABLE credenciamento (
    medico_id   INTEGER NOT NULL REFERENCES medico (pessoa_id),
    convenio_id INTEGER NOT NULL REFERENCES convenio (id),
    data_inicio DATE    NOT NULL,
    PRIMARY KEY (medico_id, convenio_id)
);

CREATE TABLE consulta (
    id            INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    paciente_id   INTEGER       NOT NULL REFERENCES paciente (pessoa_id),
    medico_id     INTEGER       NOT NULL REFERENCES medico (pessoa_id),
    convenio_id   INTEGER                REFERENCES convenio (id),
    data_consulta DATE          NOT NULL,
    valor         NUMERIC(10,2) NOT NULL CHECK (valor > 0)
);

CREATE TABLE exame_solicitado (
    consulta_id INTEGER NOT NULL REFERENCES consulta (id) ON DELETE CASCADE,
    numero      INTEGER NOT NULL,
    exame       TEXT    NOT NULL,
    PRIMARY KEY (consulta_id, numero)
);

INSERT INTO pessoa (nome, cpf, data_nascimento, logradouro, numero, bairro, cidade)
VALUES
    ('João Silva',         '111.111.111-11', '1980-03-10', 'Rua Major Gote',         '120',  'Centro',            'Patos de Minas'),
    ('Maria Souza',        '222.222.222-22', '1990-07-25', 'Rua Olegário Maciel',    '45',   'Centro',            'Patos de Minas'),
    ('José Santos',        '333.333.333-33', '1975-01-30', 'Avenida Fátima Porto',   '980',  'Lagoinha',          'Patos de Minas'),
    ('Ana Oliveira',       '444.444.444-44', '1985-11-05', 'Rua Tiradentes',         '310',  'Caiçaras',          'Patos de Minas'),
    ('Carlos Pereira',     '555.555.555-55', '1992-02-18', 'Rua Doutor Marcolino',   '77',   'Centro',            'Patos de Minas'),
    ('Fernanda Lima',      '666.666.666-66', '1988-06-12', 'Rua José de Santana',    '15',   'Planalto',          'Patos de Minas'),
    ('Ricardo Almeida',    '777.777.777-77', '1979-09-01', 'Rua Rui Barbosa',        '502',  'Brasil',            'Patos de Minas'),
    ('Patrícia Rodrigues', '888.888.888-88', '1995-12-22', 'Rua Teófilo Otoni',      '88',   'Lagoinha',          'Patos de Minas'),
    ('Bruno Costa',        '999.999.999-99', '1991-04-14', 'Avenida JK',             '1400', 'Jardim Panorâmico', 'Patos de Minas'),
    ('Juliana Carvalho',   '101.101.101-10', '1983-08-30', 'Rua Padre Caldeira',     '23',   'Centro',            'Patos de Minas'),
    ('Lucas Ferreira',     '121.121.121-12', '2014-05-02', 'Rua Major Gote',         '120',  'Centro',            'Patos de Minas'),
    ('Mariana Gomes',      '131.131.131-13', '2018-10-11', 'Avenida Fátima Porto',   '980',  'Lagoinha',          'Patos de Minas'),
    ('Felipe Ribeiro',     '141.141.141-14', '1982-07-07', 'Rua Vereador Doca',      '64',   'Caiçaras',          'Lagoa Formosa'),
    ('Laura Mendes',       '151.151.151-15', '1993-03-19', 'Rua Getúlio Vargas',     '9',    'Centro',            'Lagoa Formosa'),
    ('André Moreira',      '161.161.161-16', '1978-12-02', 'Rua Afonso Queiroz',     '230',  'Planalto',          'Patos de Minas'),
    ('Paulo Araújo',       '171.171.171-17', '1970-05-20', 'Rua Dona Luíza',         '1001', 'Centro',            'Patos de Minas'),
    ('Beatriz Nascimento', '181.181.181-18', '1981-09-14', 'Rua Dona Luíza',         '1002', 'Centro',            'Patos de Minas'),
    ('Victor Almeida',     '191.191.191-19', '1969-02-28', 'Avenida Getúlio Vargas', '300',  'Centro',            'Patos de Minas'),
    ('Camila Rodrigues',   '202.202.202-20', '1986-11-09', 'Rua Santa Terezinha',    '41',   'Brasil',            'Patos de Minas'),
    ('Thiago Santos',      '212.212.212-21', '1990-04-18', 'Rua Quintino Bocaiúva',  '17',   'Centro',            'Patos de Minas'),
    ('Daniela Alves',      '232.232.232-23', '1987-12-30', 'Rua Cônego Getúlio',     '55',   'Planalto',          'Patos de Minas');

INSERT INTO telefone (pessoa_id, numero)
VALUES
    ( 1, '34 99999-0001'), ( 1, '34 3821-0001'),  ( 2, '34 99999-0002'), ( 3, '34 99999-0003'),
    ( 4, '34 99999-0004'), ( 4, '34 3821-0004'),  ( 5, '34 99999-0005'), ( 6, '34 99999-0006'),
    ( 7, '34 99999-0007'), ( 8, '34 99999-0008'), ( 9, '34 99999-0009'), (10, '34 99999-0010'),
    (13, '34 99999-0013'), (14, '34 99999-0014'), (15, '34 99999-0015'),
    (16, '34 3822-1001'),  (17, '34 3822-1002'),  (17, '34 99888-1002'), (18, '34 3822-1003'),
    (19, '34 3822-1004'),  (20, '34 3822-1005'),  (21, '34 3822-1006');

INSERT INTO especialidade (nome)
VALUES
    ('Cardiologia'), ('Clínica Geral'), ('Ortopedia'), ('Pediatria'),
    ('Dermatologia'), ('Oftalmologia'), ('Neurologia');

INSERT INTO convenio (nome)
VALUES
    ('Vida Plena'), ('Bem Viver'), ('Amparo Saúde'), ('Nova Saúde');

INSERT INTO paciente (pessoa_id, data_cadastro, titular_id)
VALUES
    ( 1, '2026-01-10', NULL), ( 2, '2026-01-15', NULL), ( 3, '2026-02-01', NULL),
    ( 4, '2026-02-10', NULL), ( 5, '2026-03-05', NULL), ( 6, '2026-03-20', NULL),
    ( 7, '2026-04-10', NULL), ( 8, '2026-05-01', NULL), ( 9, '2026-06-15', NULL),
    (10, '2026-07-03', NULL), (11, '2026-07-20', 1),    (12, '2026-08-01', 3),
    (13, '2026-08-10', NULL), (14, '2026-09-05', 13),   (15, '2026-09-20', NULL),
    (17, '2026-08-01', NULL);

INSERT INTO medico (pessoa_id, crm, especialidade_id)
VALUES
    (16, 'CRM-MG 1001', 1), (17, 'CRM-MG 1002', 2), (18, 'CRM-MG 1003', 3),
    (19, 'CRM-MG 1004', 4), (20, 'CRM-MG 1005', 5), (21, 'CRM-MG 1006', 6);

INSERT INTO credenciamento (medico_id, convenio_id, data_inicio)
VALUES
    (16, 1, '2024-03-01'), (16, 2, '2024-03-01'), (17, 1, '2023-08-15'),
    (17, 3, '2025-01-10'), (18, 1, '2024-06-01'), (18, 2, '2025-02-01'),
    (19, 1, '2025-05-20'), (20, 3, '2026-02-01');

INSERT INTO consulta (paciente_id, medico_id, convenio_id, data_consulta, valor)
VALUES
    ( 1, 16, 1,    '2026-08-03', 180.00),
    ( 2, 16, 2,    '2026-08-04', 180.00),
    ( 3, 17, NULL, '2026-08-05', 250.00),
    ( 4, 18, 1,    '2026-08-06', 200.00),
    ( 5, 17, 3,    '2026-08-07', 150.00),
    ( 6, 16, 2,    '2026-08-10', 180.00),
    ( 7, 18, 1,    '2026-08-11', 200.00),
    ( 1, 17, 3,    '2026-08-12', 150.00),
    (12, 19, NULL, '2026-08-13', 280.00),
    ( 9, 16, 1,    '2026-08-14', 180.00),
    (10, 16, 2,    '2026-08-17', 180.00),
    (11, 19, 1,    '2026-08-18', 170.00),
    ( 2, 17, 3,    '2026-08-19', 150.00),
    ( 3, 18, NULL, '2026-08-20', 300.00),
    ( 4, 16, 2,    '2026-08-21', 180.00),
    ( 5, 17, 1,    '2026-08-24', 150.00),
    ( 6, 17, 3,    '2026-08-25', 150.00),
    ( 7, 16, NULL, '2026-08-26', 320.00),
    ( 8, 18, 2,    '2026-08-27', 200.00),
    (17, 16, 1,    '2026-08-28', 180.00);

INSERT INTO exame_solicitado (consulta_id, numero, exame)
VALUES
    ( 1, 1, 'Eletrocardiograma'),     ( 1, 2, 'Hemograma'),             ( 3, 1, 'Hemograma'),
    ( 4, 1, 'Radiografia da coluna'), ( 7, 1, 'Radiografia do joelho'), (14, 1, 'Ressonância do joelho'),
    (14, 2, 'Hemograma'),             (18, 1, 'Ecocardiograma');

SELECT
    *
FROM
    consulta;

SELECT
    *
FROM
    paciente;

SELECT
    *
FROM
    pessoa;

SELECT
    *
FROM
    medico;

SELECT
    *
FROM
    especialidade;


-- 6-Consultas
--6.1
SELECT
    pe.nome,
    pa.data_cadastro,
    DATE_PART('year' , AGE(CURRENT_DATE, pe.data_nascimento)) AS idade
FROM
    paciente AS pa JOIN pessoa AS pe ON pe.id = pa.pessoa_id
ORDER BY
    idade;

--6.2
SELECT
    pe.nome,
    m.crm,
    e.nome AS especialidade
FROM
    pessoa AS pe JOIN medico AS m 
    ON pe.id = m.pessoa_id
    JOIN especialidade AS e 
    ON m.especialidade_id = e.id;

--6.3
SELECT
    pe.id,
    pe.nome,
    pa.titular_id
FROM
    paciente AS pa JOIN pessoa AS pe ON pe.id = pa.pessoa_id
WHERE
    pa.titular_id IS NOT NULL;

SELECT
    pet.id,
    pet.nome
FROM
    paciente AS pat JOIN pessoa AS pet ON pet.id = pat.pessoa_id;

SELECT
    ped.nome AS dependente,
    pet.nome AS titular_id
FROM    
    paciente AS pad JOIN pessoa ped ON ped.id = pad.pessoa_id
    JOIN paciente AS pat ON pad.titular_id = pat.pessoa_id
    JOIN pessoa AS pet ON pat.pessoa_id = pet.id;

--Atividade restante do topico 6

--Cross JOIN
SELECT
    c.id AS consulta,
    cv.nome AS conveio,
    c.convenio_id
FROM
    consulta AS c CROSS JOIN convenio AS cv;

