-- Active: 1791332005402@@127.0.0.1@5432@bd_hortifruti@public

DROP TABLE IF EXISTS itens_venda;
DROP TABLE IF EXISTS vendas;
DROP TABLE IF EXISTS produtos;

CREATE TABLE itens_venda(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    venda_id INTEGER NOT NULL,
    data_venda DATE NOT NULL,
    bairro_entrega TEXT,
    produto_id INTEGER NOT NULL,
    produto_nome TEXT NOT NULL,
    categoria TEXT NOT NULL,
    unidade TEXT NOT NULL,
    quantidade NUMERIC(10, 3) NOT NULL,
    valor_unitario NUMERIC(10, 2) NOT NULL
);

INSERT INTO itens_venda
(venda_id, data_venda, bairro_entrega, produto_id, produto_nome,
categoria, unidade, quantidade, valor_unitario)
VALUES
-- 2026-08-03, segunda-feira
(3001, '2026-08-03', NULL, 1, 'Banana prata', 'Fruta', 'Kg', 1.235, 5.99),
(3001, '2026-08-03', NULL, 5, 'Tomate', 'Legume', 'Kg', 0.874, 7.49),
(3001, '2026-08-03', NULL, 10, 'Alface crespa', 'Verdura', 'UN', 1.000, 2.99),
(3001, '2026-08-03', NULL, 12, 'Cheiro-verde', 'Verdura', 'UN', 2.000, 2.50),
(3002, '2026-08-03', NULL, 6, 'Batata', 'Legume', 'Kg', 2.140, 4.99),
(3002, '2026-08-03', NULL, 9, 'Cebola', 'Legume', 'Kg', 0.965, 5.19),
(3003, '2026-08-03', 'Centro', 3, 'Abacaxi', 'Fruta', 'UN', 2.000, 7.90),
(3003, '2026-08-03', 'Centro', 2, 'Laranja pera', 'Fruta', 'Kg', 3.180, 3.79),
(3003, '2026-08-03', 'Centro', 8, 'Cenoura', 'Legume', 'Kg', 1.020, 4.29),
-- 2026-08-04, terca-feira
(3004, '2026-08-04', NULL, 5, 'Tomate', 'Legume', 'Kg', 1.460, 7.49),
(3004, '2026-08-04', NULL, 7, 'Batata-doce', 'Legume', 'Kg', 1.785, 4.49),
(3004, '2026-08-04', NULL, 11, 'Couve', 'Verdura', 'UN', 1.000, 3.00),
(3005, '2026-08-04', NULL, 4, 'Morango', 'Fruta', 'UN', 2.000, 9.90),
(3006, '2026-08-04', 'Lagoinha', 1, 'Banana prata', 'Fruta', 'Kg', 2.310, 5.99),
(3006, '2026-08-04', 'Lagoinha', 6, 'Batata', 'Legume', 'Kg', 1.505, 4.99),
(3006, '2026-08-04', 'Lagoinha', 10, 'Alface crespa', 'Verdura', 'UN', 2.000, 2.99),
(3006, '2026-08-04', 'Lagoinha', 12, 'Cheiro-verde', 'Verdura', 'UN', 1.000, 2.50),
-- 2026-08-05, quarta-feira
(3007, '2026-08-05', NULL, 2, 'Laranja pera', 'Fruta', 'Kg', 2.450, 3.49),
(3007, '2026-08-05', NULL, 5, 'Tomate', 'Legume', 'Kg', 0.635, 7.99),
(3008, '2026-08-05', NULL, 8, 'Cenoura', 'Legume', 'Kg', 0.780, 4.39),
(3008, '2026-08-05', NULL, 9, 'Cebola', 'Legume', 'Kg', 1.215, 5.19),
(3008, '2026-08-05', NULL, 11, 'Couve', 'Verdura', 'UN', 2.000, 3.00),
(3009, '2026-08-05', 'Centro', 3, 'Abacaxi', 'Fruta', 'UN', 1.000, 7.50),
(3009, '2026-08-05', 'Centro', 4, 'Morango', 'Fruta', 'UN', 1.000, 9.49),
(3009, '2026-08-05', 'Centro', 1, 'Banana prata', 'Fruta', 'Kg', 1.890, 6.29),
-- 2026-08-06, quinta-feira
(3010, '2026-08-06', NULL, 7, 'Batata-doce', 'Legume', 'Kg', 0.925, 4.79),
(3010, '2026-08-06', NULL, 10, 'Alface crespa', 'Verdura', 'UN', 1.000, 3.29),
(3011, '2026-08-06', NULL, 5, 'Tomate', 'Legume', 'Kg', 1.975, 8.49),
(3011, '2026-08-06', NULL, 6, 'Batata', 'Legume', 'Kg', 3.020, 5.29),
(3011, '2026-08-06', NULL, 12, 'Cheiro-verde', 'Verdura', 'UN', 3.000, 2.50),
(3012, '2026-08-06', 'Planalto', 2, 'Laranja pera', 'Fruta', 'Kg', 4.060, 3.49),
(3012, '2026-08-06', 'Planalto', 8, 'Cenoura', 'Legume', 'Kg', 1.340, 4.39),
-- 2026-08-07, sexta-feira
(3013, '2026-08-07', NULL, 1, 'Banana prata', 'Fruta', 'Kg', 0.965, 6.49),
(3013, '2026-08-07', NULL, 9, 'Cebola', 'Legume', 'Kg', 0.540, 5.49),
(3013, '2026-08-07', NULL, 11, 'Couve', 'Verdura', 'UN', 1.000, 3.50),
(3014, '2026-08-07', 'Lagoinha', 4, 'Morango', 'Fruta', 'UN', 3.000, 8.90),
(3014, '2026-08-07', 'Lagoinha', 3, 'Abacaxi', 'Fruta', 'UN', 1.000, 6.99),
-- 2026-08-08, sabado
(3015, '2026-08-08', NULL, 6, 'Batata', 'Legume', 'Kg', 1.250, 5.49),
(3016, '2026-08-08', NULL, 5, 'Tomate', 'Legume', 'Kg', 1.115, 8.99),
(3016, '2026-08-08', NULL, 7, 'Batata-doce', 'Legume', 'Kg', 1.360, 4.79);

-- Venda 3017, realizada em 08/08/2026, retirada no balcão. Itens: 1,340 kg de tomate, a R$ 8,99 o quilograma, dois pés de alface crespa, a R$ 3,49 cada, e uma bandeja de morango, a R$ 9,90.

INSERT INTO itens_venda(venda_id, data_venda, bairro_entrega, produto_id, produto_nome, categoria, unidade, quantidade, valor_unitario)
VALUES
(3017, '2026-08-08', NULL, 5, 'Tomate', 'Legume', 'Kg', 1.340, 8.99),
(3017, '2026-08-08', NULL, 10, 'Alface crespa', 'Verdura', 'UN', 2, 3.49),
(3017, '2026-08-08', NULL, 4, 'Morango', 'Fruta', 'UN', 1, 9.9);

SELECT * FROM itens_venda;

-- Consulta 1. Listar, sem repetição, o código, o nome, a categoria e a unidade de medida dos produtos vendidos, ordenados pela categoria e, dentro dela, pelo nome do produto. O resultado é o cadastro de produtos do hortifrúti, reconstruído a partir dos itens.

SELECT DISTINCT
    produto_id,
    produto_nome,
    categoria,
    unidade
FROM
    itens_venda
ORDER BY
    categoria,
    produto_nome;


-- Consulta 2. Listar venda_id, produto_nome e valor_unitario dos itens de produtos das categorias Legume e Verdura cujo valor unitário está entre 3.00 e 5.00, inclusive os extremos. Usar IN e BETWEEN. Ordenar pelo valor unitário, do maior para o menor, e, em caso de empate, pelo número da venda.

SELECT
    venda_id,
    produto_nome,
    valor_unitario
FROM
    itens_venda
WHERE
    categoria IN ('Legume', 'Verdura') AND
    valor_unitario BETWEEN 3 AND 5
ORDER BY
    valor_unitario DESC,
    venda_id;

-- Consulta 3. Listar venda_id, data_venda, produto_nome e quantidade dos itens cujo nome do produto começa com Batata, ordenados pela data e pelo número da venda.

SELECT
    venda_id,
    data_venda,
    produto_nome,
    quantidade
FROM
    itens_venda
WHERE
    produto_nome LIKE 'Batata%'
ORDER BY
    data_venda,
    venda_id;

-- Consulta 4. Listar, sem repetição, o número, a data e o bairro de entrega das vendas entregues em domicílio, ordenadas pelo número da venda.

SELECT DISTINCT
    venda_id,
    data_venda,
    bairro_entrega
FROM
    itens_venda
WHERE
    bairro_entrega IS NOT NULL
ORDER BY
    venda_id;


-- Consulta 5. O valor de cada item é quantidade * valor_unitario, arredondado a duas casas (valor_item). Com os itens ordenados pelo valor, do maior para o menor, e, em caso de empate, pelo número da venda, apresentar a segunda página de cinco itens, isto é, do sexto ao décimo. Colunas: venda_id, produto_nome, quantidade, unidade, valor_unitario e valor_item.

SELECT
    venda_id,
    produto_nome,
    quantidade,
    unidade,
    valor_unitario,
    ROUND((quantidade * valor_unitario),2) AS valor_item
FROM
    itens_venda
ORDER BY
    valor_item DESC,
    venda_id
LIMIT
    5 OFFSET 5;

-- Consulta 6. Apresentar, para cada venda, o número, a data, o destino (destino), a quantidade de itens (itens) e o valor total (valor_total), ordenado pelo valor total, do maior para o menor. O destino é o bairro de entrega ou, nas vendas sem entrega, o texto Retirada no balcao.

SELECT
    venda_id,
    data_venda,
    COALESCE(bairro_entrega,'Retirada no Balcao') destino,
    COUNT(*) AS itens,
    ROUND(SUM(quantidade * valor_unitario), 2) AS valor_total
FROM
    itens_venda
GROUP BY
    venda_id,
    data_venda,
    bairro_entrega
ORDER BY
    valor_total DESC;

-- Consulta 7. Apresentar, para cada dia, a data, a quantidade de vendas distintas (vendas), a quantidade de itens (itens) e o faturamento do dia (faturamento), ordenado pela data.
SELECT
    data_venda,
    COUNT(DISTINCT venda_id),
    COUNT(*) AS itens,
    ROUND(SUM(quantidade * valor_unitario),2) AS faturamento
FROM
    itens_venda
GROUP BY
    data_venda
ORDER BY
    data_venda;

-- Consulta 8. Apresentar, para cada produto, o código, o nome, a unidade de medida, a quantidade total vendida (qtd_total), o faturamento (faturamento), a média simples do valor unitário (media_simples) e o valor médio recebido por unidade de medida vendida (media_ponderada), ordenado pelo faturamento, do maior para o menor.

SELECT
    produto_id,
    produto_nome,
    unidade,
    ROUND(SUM(quantidade), 3) AS qtd_total,
    ROUND(SUM(quantidade * valor_unitario),2) AS faturamento,
    ROUND(AVG(valor_unitario),2) AS media_simples,
    ROUND(SUM(quantidade * valor_unitario)/SUM(quantidade),2) AS media_ponderada
FROM
    itens_venda
GROUP BY
    produto_id,
    produto_nome,
    unidade
ORDER BY
    faturamento DESC;

-- Consulta 9. Apresentar, para cada categoria, a quantidade de itens (itens), a quantidade total vendida (qtd_total) e o faturamento (faturamento), ordenado pela categoria. A quantidade total só tem significado quando soma valores da mesma unidade de medida, e o resultado deve respeitar essa regra (aula prática 04, seção 7.4).

SELECT
    categoria,
    unidade,
    COUNT(*) AS itens,
    SUM(quantidade) AS qtd_total,
    ROUND(SUM(quantidade * valor_unitario),2) AS faturamento
FROM
    itens_venda
GROUP BY
    categoria,
    unidade
ORDER BY
    categoria;

-- Consulta 10. Considerando apenas as vendas com entrega, apresentar, para cada bairro, a quantidade de vendas entregues (entregas) e o faturamento (faturamento), somente dos bairros cujo faturamento passa de 40.00, ordenado pelo faturamento, do maior para o menor.

SELECT
    bairro_entrega,
    COUNT(DISTINCT venda_id) AS qtd_entregas,
    ROUND(SUM(quantidade * valor_unitario), 2) AS faturamento
FROM
    itens_venda
WHERE
    bairro_entrega IS NOT NULL
GROUP BY
    bairro_entrega
HAVING
    SUM(quantidade * valor_unitario) > 40
ORDER BY
    faturamento DESC;

-- Consulta 11. Apresentar as vendas em que o valor total arredondado a duas casas (total_arredondado) é diferente da soma dos valores dos itens arredondados um a um (soma_dos_itens_arredondados), com as duas colunas, ordenadas pelo número da venda (aula prática 04, seção 6.3).

SELECT
    venda_id,
    ROUND(SUM(quantidade * valor_unitario), 2) AS total_arredondado,
    SUM(ROUND(quantidade * valor_unitario, 2)) AS soma_itens_arredondados
FROM
    itens_venda
GROUP BY
    venda_id
HAVING
    ROUND(SUM(quantidade * valor_unitario), 2) <> SUM(ROUND(quantidade * valor_unitario, 2))
ORDER BY
    venda_id;


-- Continuacao pratica 1

SELECT
    COUNT(*) AS linhas
FROM
    itens_venda;


SELECT
    produto_id,
    produto_nome,
    categoria,
    unidade
FROM
    itens_venda
ORDER BY
    produto_id;

-- O tomate e a tabela única
SELECT
    id,
    venda_id,
    produto_id,
    produto_nome,
    categoria
FROM
    itens_venda
WHERE
    produto_id = 5
ORDER BY
    venda_id;

-- UPDATE
UPDATE itens_venda
SET categoria = 'Fruta'
WHERE
    produto_id = 5;

-- Tabela produto
CREATE TABLE produto(
    id  INTEGER PRIMARY KEY,
    nome TEXT NOT NULL UNIQUE,
    categoria TEXT NOT NULL CHECK(categoria IN ('Fruta', 'Legume', 'Verdura')),
    unidade TEXT NOT NULL CHECK(unidade IN('Kg', 'UN'))
);

INSERT INTO produto(id, nome, categoria, unidade)
SELECT DISTINCT
    produto_id,
    produto_nome,
    categoria,
    unidade
FROM
    itens_venda;

SELECT
    *
FROM
    produto;

-- Ajuste na table itens_venda
ALTER Table itens_venda
    ADD CONSTRAINT fk_itens_venda_produto
    FOREIGN KEY (produto_id) REFERENCES produto(id);


ALTER TABLE itens_venda
    DROP COLUMN produto_nome,
    DROP COLUMN categoria,
    DROP COLUMN unidade;

SELECT
    *
FROM
    itens_venda

SELECT
    *
FROM
    produto
WHERE
    id = 2;

-- INNER JOIN entre tabelas
--Itens da venda 3017, com os dados do produto
SELECT
    i.id,
    i.venda_id,
    p.nome as produto,
    p.categoria,
    p.unidade,
    i.quantidade,
    i.valor_unitario
FROM
        itens_venda AS i
    INNER JOIN
        produto AS p
    ON p.id = i.produto_id
WHERE
    i.venda_id = 3017
ORDER BY
    i.id;

-- Realizar a consulta 8 da prática.
-- Consulta 8. Apresentar, para cada produto, o código, o nome, a unidade de medida, a quantidade total vendida (qtd_total), o faturamento (faturamento), a média simples do valor unitário (media_simples) e o valor médio recebido por unidade de medida vendida (media_ponderada), ordenado pelo faturamento, do maior para o menor.
SELECT
    p.id,
    p.nome,
    p.unidade,
    SUM(i.quantidade) AS qtd_total,
    ROUND(SUM(i.quantidade * i.valor_unitario),2) AS faturamento,
    ROUND(AVG(i.valor_unitario),2) AS media_simples,
    ROUND((SUM(i.quantidade * i.valor_unitario)/SUM(i.quantidade)),2) AS media_ponderada
FROM
        produto AS p
    INNER JOIN
        itens_venda AS i
    ON
        --i.produto_id = p.id
        p.id = i.produto_id
GROUP BY
    p.id,
    p.nome,
    p.unidade
ORDER BY
    faturamento DESC;

-- Consulta 9. Apresentar, para cada categoria, a quantidade de itens (itens), a quantidade total vendida (qtd_total) e o faturamento (faturamento), ordenado pela categoria. A quantidade total só tem significado quando soma valores da mesma unidade de medida, e o resultado deve respeitar essa regra (aula prática 04, seção 7.4).
SELECT
    p.categoria,
    COUNT(*) AS qtd_itens,
    SUM(i.quantidade) AS quantidade,
    ROUND(SUM(i.quantidade * i.valor_unitario),2) AS faturamento
FROM
        itens_venda AS i
    INNER JOIN
        produto AS p
    ON
        p.id = i.produto_id
GROUP BY
    p.categoria,
    p.unidade
ORDER BY
    categoria;

-- LEFT JOIN: produto que não estão em itens_venda, quantidade vendida de cada produto

SELECT
    p.id,
    p.nome,
    COUNT(i.id) AS itens_vendidos
FROM
        produto AS p
    LEFT JOIN
        itens_venda AS i
    ON
        i.produto_id = p.id
GROUP BY
    p.id,
    p.nome
ORDER BY
    itens_vendidos,
    p.id;

INSERT INTO produto(id, nome, categoria, unidade)
VALUES (13, 'Pimentao', 'Legume', 'Kg');


SELECT
    venda_id,
    data_venda,
    bairro_entrega,
    produto_id
FROM
    itens_venda
WHERE
    venda_id = 3006
ORDER BY
    id;

CREATE TABLE vendas(
    id  INTEGER PRIMARY KEY,
    data_venda DATE NOT NULL,
    bairro_entrega TEXT
);


INSERT INTO vendas(id, data_venda, bairro_entrega)
SELECT DISTINCT
    venda_id,
    data_venda,
    bairro_entrega
FROM
    itens_venda;

SELECT
    *
FROM
    vendas;


ALTER TABLE itens_venda
    ADD CONSTRAINT fk_itens_venda_vendas
    FOREIGN KEY (venda_id) REFERENCES vendas(id);

SELECT
    v.data_venda,
    i.quantidade,
    i.valor_unitario
FROM
    vendas AS v INNER JOIN itens_venda AS i ON i.venda_id = v.id
    INNER JOIN
    produtos AS p ON i.produto_id = p.id
ORDER BY
    data_venda
;

ALTER TABLE itens_venda
    ADD CONSTRAINT uq_itens_venda_venda_produto
    UNIQUE (venda_id, produto_id);

ALTER TABLE itens_venda
    ADD CONSTRAINT ck_itens_vendas_quantidade
    CHECK (quantidade > 0);

SELECT
    v.id,
    v.data_venda,
    COALESCE(v.bairro_entrega, 'Retirada no balcao'),
    COUNT(i.id),
    ROUND(SUM(i.quantidade * i.valor_unitario), 2) AS valor_unitario
FROM
    vendas AS v INNER JOIN itens_venda AS i 
ON
    i.venda_id = v.id
GROUP BY
    v.id,
    v.data_venda,
    v.bairro_entrega
ORDER BY
    i.venda_id;
;

INSERT INTO venda (id, data_venda, bairro_entrega)
VALUES(3018, '2026-08-10', 'Centro');

INSERT INTO itens_venda(venda_id, produto_id, quantidade, valor_unitario)
VALUES
    (3018, 13, 0.450, 9.98),
    (3018, 5, 1.120, 8.89),
    (3018, 1, 1.600, 6.49);