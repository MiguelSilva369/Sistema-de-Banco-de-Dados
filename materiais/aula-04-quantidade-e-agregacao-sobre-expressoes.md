# Aula 04. Quantidade, unidade de medida e agregação sobre expressões

**Disciplina:** Sistemas de Banco de Dados I. Sistemas de Informação. UNIPAM.
**Itens da ementa:** 4.3, consulta de recuperação básica. 7.1, funções de agregação aplicadas a expressões.
**Referência:** ELMASRI, R. NAVATHE, S. *Sistemas de Banco de Dados*. 7. ed. São Paulo: Pearson. Capítulos 1, 6 e 7.
**Ambiente:** PostgreSQL 17 em contêiner Docker, acessado pela extensão Database Client.
**Cenário:** banco de dados `bd_vendas`, tabela `vendas_itens2`, com 50 registros. Todo o código necessário está neste arquivo.

---

## Sumário

1. Objetivo
2. O minimundo ampliado
3. A tabela `vendas_itens2`
4. Recuperação sobre o novo cenário
5. O valor de um item
6. Agregação sobre expressões: o total de cada venda
7. Agregação por produto
8. Boas práticas consolidadas
9. Erros frequentes e leitura das mensagens
10. Script consolidado
11. Exercícios
12. Gabarito
13. Referências

---

## 1. Objetivo

O arquivo 03 completou a consulta de recuperação sobre a tabela `vendas_itens`: operadores, filtros, ordenação, funções de agregação e `HAVING`. Este arquivo aplica esses mesmos comandos a cálculos mais completos.

O cenário continua sendo o de vendas, ampliado com duas informações em cada item: a quantidade vendida e a unidade de medida do produto. Com elas, o valor de um item é obtido pela multiplicação entre duas colunas, e o valor de uma venda pela soma desses resultados. As consultas passam a combinar, em uma mesma instrução, operadores aritméticos, funções de agregação, agrupamento e arredondamento.

Nenhuma instrução nova é introduzida. O que se amplia é a complexidade dos cálculos: as funções de agregação, que no arquivo 03 recebiam uma coluna, passam a receber também uma **expressão**.

Ao final, os seguintes resultados devem estar assegurados.

| Resultado | Descrição |
|---|---|
| Minimundo | Descrever o cenário ampliado, com quantidade e unidade de medida, e as regras que ele passa a ter |
| Tipo | Escolher a escala de uma coluna `NUMERIC` a partir da grandeza que ela representa |
| Expressão por linha | Calcular o valor de cada item a partir da quantidade e do valor unitário |
| Agregação sobre expressão | Somar uma expressão, e não apenas uma coluna |
| Média ponderada | Distinguir a média dos preços da média do preço por unidade vendida |
| Arredondamento | Decidir em que ponto do cálculo arredondar, e conhecer a consequência da decisão |

### 1.1 Delimitação

Continua fora do escopo a junção de tabelas, tratada no roteiro prático 01, e a subconsulta, tratada no roteiro prático 02. A tabela continua única, e as funções de agregação são as mesmas sete da seção 9.1 do arquivo 03.

---

## 2. O minimundo ampliado

### 2.1 O que o cenário acrescenta

O cenário do arquivo 03 registra, para cada item de venda, o produto, o valor unitário e a data. O cenário deste arquivo mantém essas informações e acrescenta duas: quantas unidades, ou quantos quilogramas, foram vendidos, e em qual unidade de medida o produto é vendido.

A ampliação abre uma família de cálculos que combinam colunas entre si: o valor de cada item, o valor de cada venda, a quantidade vendida de cada produto e o preço médio por unidade vendida. Todos eles são escritos com os comandos já conhecidos.

### 2.2 As regras do minimundo

O recorte continua sendo a operação de venda de uma loja, observada do ponto de vista dos itens vendidos. As regras, enunciadas em linguagem natural, passam a ser as seguintes.

1. A loja realiza vendas. Cada venda é identificada por um número e ocorre em uma data.
2. Uma venda contém um ou mais itens.
3. Cada item de venda refere-se a um produto, identificado por um número.
4. Cada item registra a quantidade vendida, que é sempre maior que zero.
5. Cada produto é vendido em uma unidade de medida: por unidade, representada por `UN`, ou por quilograma, representada por `Kg`. Um mesmo produto é sempre vendido na mesma unidade de medida.
6. Cada item registra o valor unitário praticado naquela venda, que é o preço de uma unidade de medida do produto. O mesmo produto pode ter preços diferentes em vendas diferentes.
7. O valor de um item é a quantidade multiplicada pelo valor unitário. O valor de uma venda é a soma dos valores dos seus itens.

A regra 7 é a mais importante do arquivo, e é a única que não corresponde a nenhuma coluna. O valor do item e o valor da venda são **atributos derivados**: podem ser obtidos a partir de outros atributos, e por isso a tabela não os armazena. O conceito recebe tratamento formal na modelagem conceitual, no roteiro prático 02.

A regra 5 do arquivo 03, sobre a observação em texto livre, não foi mantida. A tabela deste arquivo não tem coluna de observação, porque os operadores que dependiam dela já foram tratados.

### 2.3 O preço praticado em cada venda

Na tabela deste arquivo, o valor unitário de um mesmo produto varia de uma venda para outra. O produto 4, por exemplo, foi vendido a `225.00`, `220.00`, `218.50`, `217.50` e `215.20`. O valor registrado no item é o preço **praticado no momento da venda**, e esse preço é um fato histórico: se o preço do produto for alterado, as vendas já realizadas continuam registrando o preço da data em que ocorreram.

Quando o preço de um produto é fixo, repeti-lo em cada item é redundância, como descrito no arquivo 03, seção 4.5. Quando o preço é o praticado em cada venda, cada linha registra um fato próprio, e as linhas precisam continuar independentes.

É a situação apontada no arquivo 03, seção 2.4: o valor unitário é um atributo do **relacionamento** entre venda e produto, e não do produto isoladamente. Um sistema comercial completo costuma ter os dois valores, o preço de tabela, guardado com o produto, e o preço praticado, guardado com o item.

### 2.4 A redundância da unidade de medida

A regra 5 diz que um produto é sempre vendido na mesma unidade de medida. Ainda assim, a coluna `unidade` está em cada item. O fato "o produto 3 é vendido por quilograma" está armazenado cinco vezes, uma para cada item do produto 3.

Aqui a repetição é redundância de fato. Se o produto 3 passasse a ser vendido por unidade, seria necessário alterar cinco linhas, e esquecer uma deixaria o produto com duas unidades de medida ao mesmo tempo.

A coluna `data_venda` repete o mesmo problema, como já observado no arquivo 03: a data pertence à venda e está armazenada uma vez por item.

Um critério ajuda a distinguir os casos. Um valor repetido é redundância quando depende de alguma coisa menor do que a linha em que está. A unidade depende apenas do produto. A data depende apenas da venda. O valor unitário depende do produto **e** da venda, e por isso pertence ao item. Esse critério tem nome, **dependência funcional**, e é assunto do roteiro prático 02.

### 2.5 O recorte: o que continua de fora

- **O cliente.** Não se sabe quem comprou.
- **O nome do produto.** Existe apenas o número que o identifica.
- **As tabelas de vendas e de produtos.** Continua sem ser possível declarar chave estrangeira, pela razão exposta no arquivo 03, seção 4.4.
- **Descontos, frete e impostos.** O valor de uma venda é exatamente a soma dos valores dos seus itens, conforme a regra 7.
- **A observação.** Retirada deste cenário, conforme a seção 2.2.

### 2.6 Vocabulário

| Termo | Significado |
|---|---|
| Grandeza | Propriedade que se pode medir ou contar, como a massa ou o número de peças |
| Unidade de medida | Referência em que a grandeza é expressa, como o quilograma ou a unidade |
| Atributo derivado | Atributo cujo valor pode ser calculado a partir de outros atributos |
| Escala | Quantidade de dígitos à direita da vírgula em um número `NUMERIC` |
| Média ponderada | Média em que cada valor pesa conforme uma quantidade associada a ele |
| Dependência funcional | Relação em que o valor de um atributo é determinado pelo valor de outro |

---

## 3. A tabela `vendas_itens2`

### 3.1 O mesmo banco, uma tabela nova

O minimundo deste arquivo é o do arquivo 03, ampliado. Pela regra estabelecida lá, um banco de dados por minimundo, a tabela nova é criada em `bd_vendas`, e a conexão continua a mesma:

```sql
-- Active: 1787177433004@@127.0.0.1@5432@bd_vendas@public
```

A tabela `vendas_itens` permanece como está. As duas tabelas convivem no mesmo banco, cada uma com as consultas do seu arquivo.

O nome `vendas_itens2` é aceitável em um cenário de estudo, onde a finalidade é justamente ter duas versões da mesma tabela. Em um esquema real, um sufixo numérico não informa o que distingue uma tabela da outra, e o nome deveria dizer isso.

### 3.2 Estrutura

| Coluna | Tipo | Obrigatória | Representa |
|---|---|---|---|
| `id` | `INTEGER` | Sim | Identificador da linha, gerado pelo SGBD |
| `venda_id` | `INTEGER` | Sim | Número da venda a que o item pertence |
| `produto_id` | `INTEGER` | Sim | Número do produto vendido |
| `quantidade` | `NUMERIC(10,3)` | Sim | Quantidade vendida, na unidade de medida do produto |
| `unidade` | `TEXT` | Sim | Unidade de medida, `UN` ou `Kg` |
| `valor_unitario` | `NUMERIC(10,2)` | Sim | Preço de uma unidade de medida, praticado nesta venda |
| `data_venda` | `DATE` | Sim | Data em que a venda ocorreu |

Todas as colunas são obrigatórias. Diferentemente do cenário do arquivo 03, nenhuma admite ausência de valor.

A ordem das colunas acompanha a leitura natural de um item: "duas `UN` a `88.78`", "0,450 `Kg` a `45.00`".

### 3.3 A escala da quantidade

`NUMERIC(10,3)` declara precisão 10 e escala 3: até dez dígitos no total, dos quais três à direita da vírgula. O maior valor representável é `9999999.999`.

A escala 3 vem da grandeza. Um quilograma tem mil gramas, e três casas decimais registram a massa com a precisão de um grama: `0.450` quilograma são 450 gramas. A escala de uma coluna de quantidade é a menor fração que o minimundo precisa registrar.

Duas alternativas mostram por que a escolha importa.

**`INTEGER`.** Seria adequado se todos os produtos fossem vendidos por unidade, porque uma contagem de peças não se fraciona. Com produtos vendidos por quilograma, deixa de servir. Uma coluna `INTEGER` não recusa o valor `0.450`: o SGBD o converte para inteiro, arredondando, e armazena `0`. Três itens do produto 3 passariam a ter quantidade zero, e o valor da venda 2010 cairia de `113.92` para `99.90`.

**`NUMERIC(10,2)`.** Quando o valor informado tem mais casas decimais do que a escala declarada, o PostgreSQL arredonda o valor para a escala da coluna, também sem erro. O item de `0.225` quilograma do produto 3 seria armazenado como `0.23`. Cinco gramas a mais, ao preço de `47.20` o quilograma, transformariam um item de `10.62` em um item de `10.86`.

Nos dois casos o SGBD não recusa o dado. Ele o transforma para caber no tipo declarado, e a perda acontece em silêncio, no momento da inserção. O erro só aparece no sentido oposto: um valor com dígitos demais **à esquerda** da vírgula, como `10000000.000`, é recusado com `numeric field overflow`.

**Regra de boa prática:** a escala é decisão de modelagem, e não detalhe de sintaxe. Dinheiro em centavos pede escala 2. Massa em gramas, expressa em quilogramas, pede escala 3. Uma escala menor do que a necessária destrói dados sem aviso.

### 3.4 A unidade de medida como texto livre

A coluna `unidade` é `TEXT NOT NULL`. O minimundo admite dois valores, e o esquema admite qualquer texto: `'kg'`, `'KG'`, `'quilo'` ou `'Kg '`, com um espaço no final.

Para o SGBD, esses textos são todos diferentes. Um agrupamento por `unidade` formaria um grupo para cada grafia, e um filtro `WHERE unidade = 'Kg'` deixaria de fora as linhas escritas de outro modo. É o mesmo problema observado no arquivo 02, seção 2.5, com a coluna `disciplina`.

O símbolo oficial do quilograma é `kg`, em minúsculas. O cenário armazena `Kg`, como no código de origem, e o que importa para o banco é que todas as linhas usem a mesma grafia.

A regra 4, que exige quantidade maior que zero, está na mesma situação: nada no esquema impede uma quantidade `0` ou negativa. As duas regras são **enunciadas**, e não **declaradas**, como a chave estrangeira do arquivo 03, seção 4.4. A cláusula que restringe uma coluna a uma condição, `CHECK`, é tratada no roteiro prático 01.

### 3.5 A instrução completa

```sql
DROP TABLE IF EXISTS vendas_itens2;

CREATE TABLE vendas_itens2 (
    id             INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    venda_id       INTEGER       NOT NULL,
    produto_id     INTEGER       NOT NULL,
    quantidade     NUMERIC(10,3) NOT NULL,
    unidade        TEXT          NOT NULL,
    valor_unitario NUMERIC(10,2) NOT NULL,
    data_venda     DATE          NOT NULL
);
```

Duas diferenças em relação ao código de origem, ambas de forma.

**O código de origem escrevia `CREATE TABLE IF NOT EXISTS` logo depois do `DROP TABLE IF EXISTS`.** Depois do `DROP`, a tabela nunca existe, e a cláusula `IF NOT EXISTS` não tem o que fazer. Ela não provoca erro, mas sugere uma dúvida que o script não tem. A razão de preferir `DROP` seguido de `CREATE` está no arquivo 03, seção 4.6.

**O código de origem tinha `not NULL`, em minúsculas, em uma das linhas.** O comando funciona, porque o SGBD não diferencia caixa em palavras reservadas. O material mantém as palavras reservadas sempre em maiúsculas, pela regra de legibilidade do arquivo 03, seção 10.4.

Conferência da tabela recém-criada, antes de qualquer inserção:

```sql
SELECT * FROM vendas_itens2;
```

Sete colunas, nenhuma linha.

### 3.6 Carga dos dados

```sql
INSERT INTO vendas_itens2 (venda_id, produto_id, quantidade, unidade, valor_unitario, data_venda) VALUES
-- Cinco vendas com cinco itens cada (venda_id 2001 a 2005)
(2001,  1,  1.000, 'UN', 150.55, '2025-09-01'),
(2001,  3,  0.450, 'Kg',  45.00, '2025-09-01'),
(2001,  5,  3.450, 'Kg',  12.75, '2025-09-01'),
(2001,  9,  2.000, 'UN',  88.78, '2025-09-01'),
(2001, 10, 20.000, 'UN',  10.00, '2025-09-01'),

(2002,  2,  1.000, 'UN',  99.90, '2025-09-02'),
(2002,  4,  1.000, 'UN', 225.00, '2025-09-02'),
(2002,  6,  0.874, 'Kg',  35.00, '2025-09-02'),
(2002,  8,  0.895, 'Kg',  34.50, '2025-09-02'),
(2002,  1,  2.000, 'UN', 150.55, '2025-09-02'),

(2003,  7,  1.000, 'UN', 199.99, '2025-09-03'),
(2003,  9,  3.000, 'UN',  89.15, '2025-09-03'),
(2003,  3,  0.860, 'Kg',  46.15, '2025-09-03'),
(2003,  2,  1.000, 'UN',  99.90, '2025-09-03'),
(2003,  5,  2.150, 'Kg',  12.80, '2025-09-03'),

(2004,  4,  1.000, 'UN', 220.00, '2025-09-04'),
(2004,  6,  0.978, 'Kg',  35.00, '2025-09-04'),
(2004,  1,  1.000, 'UN', 155.65, '2025-09-04'),
(2004,  7,  1.000, 'UN', 200.26, '2025-09-04'),
(2004, 10, 12.000, 'UN',   9.50, '2025-09-04'),

(2005,  8,  0.750, 'Kg',  35.90, '2025-09-05'),
(2005,  9,  1.000, 'UN',  90.85, '2025-09-05'),
(2005,  2,  2.000, 'UN',  99.90, '2025-09-05'),
(2005,  3,  0.720, 'Kg',  46.15, '2025-09-05'),
(2005,  4,  2.000, 'UN', 218.50, '2025-09-05'),

-- Quatro vendas com quatro itens cada (venda_id 2006 a 2009)
(2006,  1,  3.000, 'UN', 150.55, '2025-09-06'),
(2006,  5,  3.784, 'Kg',  12.95, '2025-09-06'),
(2006,  9,  1.000, 'UN',  90.85, '2025-09-06'),
(2006, 10,  8.000, 'UN',   9.10, '2025-09-06'),

(2007,  7,  1.000, 'UN', 201.46, '2025-09-07'),
(2007,  6,  0.645, 'Kg',  38.90, '2025-09-07'),
(2007,  8,  0.789, 'Kg',  33.45, '2025-09-07'),
(2007,  2,  2.000, 'UN',  99.90, '2025-09-07'),

(2008,  3,  0.225, 'Kg',  47.20, '2025-09-08'),
(2008,  4,  1.000, 'UN', 217.50, '2025-09-08'),
(2008,  1,  1.000, 'UN', 158.10, '2025-09-08'),
(2008,  9,  2.000, 'UN',  92.85, '2025-09-08'),

(2009,  5,  4.950, 'Kg',  13.10, '2025-09-09'),
(2009, 10, 16.000, 'UN',   8.90, '2025-09-09'),
(2009,  6,  0.745, 'Kg',  39.10, '2025-09-09'),
(2009,  7,  2.000, 'UN', 201.46, '2025-09-09'),

-- Duas vendas com dois itens cada (venda_id 2010 e 2011)
(2010,  2,  1.000, 'UN',  99.90, '2025-09-10'),
(2010,  3,  0.297, 'Kg',  47.20, '2025-09-10'),

(2011,  8,  0.654, 'Kg',  31.50, '2025-09-11'),
(2011,  9,  4.000, 'UN',  92.85, '2025-09-11'),

-- Cinco vendas com um item cada (venda_id 2012 a 2016)
(2012,  4,  2.000, 'UN', 215.20, '2025-09-12'),
(2013,  1,  2.000, 'UN', 158.10, '2025-09-13'),
(2014, 10,  9.000, 'UN',   8.40, '2025-09-14'),
(2015,  5,  2.560, 'Kg',  13.25, '2025-09-15'),
(2016,  7,  1.000, 'UN', 203.45, '2025-09-16');
```

Três pontos merecem comentário nesta instrução.

**A quantidade está sempre escrita com três casas decimais.** Escrever `1` em lugar de `1.000` teria o mesmo efeito, porque o valor é armazenado na escala da coluna. As três casas no próprio dado tornam a escala visível para quem lê o script.

**Os produtos vendidos por unidade têm quantidades inteiras.** O esquema não exige isso. Uma quantidade `1.500` de um produto `UN` seria aceita, embora não represente nada no minimundo. É mais uma regra enunciada e não declarada.

**A unidade de medida está escrita em cada linha.** É a redundância descrita na seção 2.4, vista agora no próprio script: o texto `'Kg'` do produto 3 é digitado cinco vezes.

### 3.7 Conferência

```sql
SELECT * FROM vendas_itens2;
```

A ferramenta deve informar **50 linhas**. Primeiras linhas do resultado:

| id | venda_id | produto_id | quantidade | unidade | valor_unitario | data_venda |
|---|---|---|---|---|---|---|
| 1 | 2001 | 1 | 1.000 | UN | 150.55 | 2025-09-01 |
| 2 | 2001 | 3 | 0.450 | Kg | 45.00 | 2025-09-01 |
| 3 | 2001 | 5 | 3.450 | Kg | 12.75 | 2025-09-01 |
| 4 | 2001 | 9 | 2.000 | UN | 88.78 | 2025-09-01 |
| 5 | 2001 | 10 | 20.000 | UN | 10.00 | 2025-09-01 |

A coluna `quantidade` mostra três casas decimais mesmo quando o valor é inteiro, como em `1.000`. A escala faz parte do tipo, e o valor é exibido com ela.

Composição do conjunto, útil para conferir os exercícios:

| Grandeza | Valor |
|---|---|
| Linhas | 50 |
| Vendas distintas | 16, de 2001 a 2016 |
| Produtos distintos | 10, de 1 a 10 |
| Datas distintas | 16, de 2025-09-01 a 2025-09-16 |
| Itens vendidos por unidade | 32 |
| Itens vendidos por quilograma | 18 |
| Menor quantidade | 0.225 |
| Maior quantidade | 20.000 |

Unidade de medida e faixa de preço de cada produto:

| produto_id | unidade | Linhas | Menor valor unitário | Maior valor unitário |
|---|---|---|---|---|
| 1 | UN | 6 | 150.55 | 158.10 |
| 2 | UN | 5 | 99.90 | 99.90 |
| 3 | Kg | 5 | 45.00 | 47.20 |
| 4 | UN | 5 | 215.20 | 225.00 |
| 5 | Kg | 5 | 12.75 | 13.25 |
| 6 | Kg | 4 | 35.00 | 39.10 |
| 7 | UN | 5 | 199.99 | 203.45 |
| 8 | Kg | 4 | 31.50 | 35.90 |
| 9 | UN | 6 | 88.78 | 92.85 |
| 10 | UN | 5 | 8.40 | 10.00 |

Cada produto tem uma única unidade de medida, conforme a regra 5. Somente o produto 2 manteve o mesmo preço em todas as vendas. Nos demais, o preço variou, conforme a regra 6.

---

## 4. Recuperação sobre o novo cenário

### 4.1 Os itens de um produto

```sql
-- Vendas em que o produto 1 aparece
SELECT
    venda_id,
    quantidade,
    unidade,
    valor_unitario,
    data_venda
FROM
    vendas_itens2
WHERE
    produto_id = 1;
```

Resultado completo, seis linhas:

| venda_id | quantidade | unidade | valor_unitario | data_venda |
|---|---|---|---|---|
| 2001 | 1.000 | UN | 150.55 | 2025-09-01 |
| 2002 | 2.000 | UN | 150.55 | 2025-09-02 |
| 2004 | 1.000 | UN | 155.65 | 2025-09-04 |
| 2006 | 3.000 | UN | 150.55 | 2025-09-06 |
| 2008 | 1.000 | UN | 158.10 | 2025-09-08 |
| 2013 | 2.000 | UN | 158.10 | 2025-09-13 |

Sem `ORDER BY`, a ordem das linhas não é garantida. A tabela acima segue a ordem de inserção.

A coluna `produto_id` não foi pedida, porque o filtro já determina o seu valor: seria uma coluna com o número `1` repetido seis vezes.

O resultado mostra as regras 5 e 6 em funcionamento. A unidade é sempre a mesma. O preço, não: `150.55` nas vendas 2001, 2002 e 2006, `155.65` na venda 2004 e `158.10` nas vendas 2008 e 2013.

### 4.2 Todos os itens de uma venda

```sql
-- Todas as informacoes da venda 2001
SELECT
    *
FROM
    vendas_itens2
WHERE
    venda_id = 2001;
```

Resultado completo, cinco linhas:

| id | venda_id | produto_id | quantidade | unidade | valor_unitario | data_venda |
|---|---|---|---|---|---|---|
| 1 | 2001 | 1 | 1.000 | UN | 150.55 | 2025-09-01 |
| 2 | 2001 | 3 | 0.450 | Kg | 45.00 | 2025-09-01 |
| 3 | 2001 | 5 | 3.450 | Kg | 12.75 | 2025-09-01 |
| 4 | 2001 | 9 | 2.000 | UN | 88.78 | 2025-09-01 |
| 5 | 2001 | 10 | 20.000 | UN | 10.00 | 2025-09-01 |

Cada linha se lê como uma frase. A segunda diz: na venda 2001, foram vendidos 450 gramas do produto 3, a `45.00` o quilograma. A quinta diz: na mesma venda, foram vendidas vinte unidades do produto 10, a `10.00` cada.

O `SELECT *` é adequado aqui, porque a consulta é exploratória e a intenção é justamente ver todas as colunas. A regra de listar as colunas, do arquivo 03, seção 10.2, vale para consultas que permanecem em um script ou em uma aplicação.

---

## 5. O valor de um item

### 5.1 A expressão `quantidade * valor_unitario`

A regra 7 do minimundo, escrita em SQL, é uma expressão na lista do `SELECT`, recurso estabelecido no arquivo 03, seção 6.2.

```sql
SELECT
    venda_id,
    produto_id,
    quantidade,
    unidade,
    valor_unitario,
    quantidade * valor_unitario AS valor_item
FROM
    vendas_itens2
WHERE
    venda_id = 2001;
```

Resultado completo, cinco linhas:

| venda_id | produto_id | quantidade | unidade | valor_unitario | valor_item |
|---|---|---|---|---|---|
| 2001 | 1 | 1.000 | UN | 150.55 | 150.55000 |
| 2001 | 3 | 0.450 | Kg | 45.00 | 20.25000 |
| 2001 | 5 | 3.450 | Kg | 12.75 | 43.98750 |
| 2001 | 9 | 2.000 | UN | 88.78 | 177.56000 |
| 2001 | 10 | 20.000 | UN | 10.00 | 200.00000 |

A expressão é calculada linha a linha, e o resultado continua com cinco linhas. A coluna `valor_item` não existe na tabela. Ela é produzida pela consulta, a cada execução, a partir das duas colunas que existem.

### 5.2 A escala do resultado

Os valores de `valor_item` têm cinco casas decimais. A regra é a mesma do arquivo 03, seção 6.2: multiplicar um número de escala 3 por um de escala 2 produz um número de escala 5. O SGBD não arredonda por conta própria.

As casas adicionais não são enfeite. O terceiro item vale `43.98750` porque 3,450 quilogramas a `12.75` resultam exatamente em 43 reais e 98,75 centavos. A fração de centavo existe no cálculo e não existe no caixa, e decidir o que fazer com ela é o assunto da seção 6.3.

### 5.3 Arredondamento para a apresentação

```sql
SELECT
    venda_id,
    produto_id,
    quantidade,
    unidade,
    valor_unitario,
    ROUND(quantidade * valor_unitario, 2) AS valor_item
FROM
    vendas_itens2
WHERE
    venda_id = 2001;
```

| venda_id | produto_id | quantidade | unidade | valor_unitario | valor_item |
|---|---|---|---|---|---|
| 2001 | 1 | 1.000 | UN | 150.55 | 150.55 |
| 2001 | 3 | 0.450 | Kg | 45.00 | 20.25 |
| 2001 | 5 | 3.450 | Kg | 12.75 | 43.99 |
| 2001 | 9 | 2.000 | UN | 88.78 | 177.56 |
| 2001 | 10 | 20.000 | UN | 10.00 | 200.00 |

`ROUND` recebe a expressão inteira e a arredonda a duas casas. O valor `43.9875` passou a `43.99`.

---

## 6. Agregação sobre expressões: o total de cada venda

### 6.1 `SUM` recebe uma expressão

O argumento de uma função de agregação não precisa ser uma coluna. Pode ser qualquer expressão calculável em cada linha. O SGBD calcula a expressão linha a linha, e só depois soma os resultados.

```sql
-- Valor da venda 2001
SELECT
    SUM(quantidade * valor_unitario) AS valor_total
FROM
    vendas_itens2
WHERE
    venda_id = 2001;
```

| valor_total |
|---|
| 592.34750 |

O número é a soma dos cinco valores de `valor_item` da seção 5.1: `150.55 + 20.25 + 43.9875 + 177.56 + 200.00`. Arredondado a centavos, o valor da venda 2001 é `592.35`.

A ordem dos operadores dentro da função é essencial. A expressão `SUM(quantidade) * SUM(valor_unitario)` também é aceita pelo SGBD, e calcula outra coisa: soma todas as quantidades da venda, soma todos os preços e multiplica um total pelo outro. Para a venda 2001, o resultado seria `26.900 * 307.08`, isto é, `8260.45200`, um número sem significado, que multiplica as vinte unidades do produto 10 pelo preço do produto 1 e por todos os outros. A soma dos produtos não é o produto das somas.

### 6.2 O valor total de cada venda

```sql
-- Valor total de cada venda
SELECT
    venda_id,
    SUM(quantidade * valor_unitario) AS valor_total_venda,
    data_venda
FROM
    vendas_itens2
GROUP BY
    venda_id,
    data_venda
ORDER BY
    data_venda;
```

Resultado completo, dezesseis linhas:

| venda_id | valor_total_venda | data_venda |
|---|---|---|
| 2001 | 592.34750 | 2025-09-01 |
| 2002 | 687.46750 | 2025-09-02 |
| 2003 | 634.54900 | 2025-09-03 |
| 2004 | 724.14000 | 2025-09-04 |
| 2005 | 787.80300 | 2025-09-05 |
| 2006 | 664.30280 | 2025-09-06 |
| 2007 | 452.74255 | 2025-09-07 |
| 2008 | 571.92000 | 2025-09-08 |
| 2009 | 639.29450 | 2025-09-09 |
| 2010 | 113.91840 | 2025-09-10 |
| 2011 | 392.00100 | 2025-09-11 |
| 2012 | 430.40000 | 2025-09-12 |
| 2013 | 316.20000 | 2025-09-13 |
| 2014 | 75.60000 | 2025-09-14 |
| 2015 | 33.92000 | 2025-09-15 |
| 2016 | 203.45000 | 2025-09-16 |

Três observações.

**`data_venda` está no `GROUP BY`** pela mesma razão exposta no arquivo 03, seção 9.4: ela aparece na lista do `SELECT` sem estar dentro de uma função de agregação. O acréscimo não altera os grupos, porque todos os itens de uma venda têm a mesma data.

**A ordenação por data coincide com a ordenação por venda.** Neste cenário, cada venda ocorre em um dia distinto. A coincidência é uma propriedade destes dados, e não uma regra do minimundo.

**Os totais têm cinco casas decimais.** `SUM` preserva a escala daquilo que soma, e aquilo que soma tem escala 5. Para leitura, o total passa por `ROUND`, como nas seções seguintes.

### 6.3 Arredondar antes ou depois de somar

Há duas formas de chegar a um total em centavos: somar os valores exatos e arredondar o total, ou arredondar cada item e somar os valores arredondados. Na maior parte das vendas, as duas coincidem. Em duas delas, não.

```sql
SELECT
    venda_id,
    ROUND(SUM(quantidade * valor_unitario), 2) AS total_arredondado,
    SUM(ROUND(quantidade * valor_unitario, 2)) AS soma_dos_itens_arredondados
FROM
    vendas_itens2
WHERE
    venda_id IN (2005, 2009)
GROUP BY
    venda_id
ORDER BY
    venda_id;
```

| venda_id | total_arredondado | soma_dos_itens_arredondados |
|---|---|---|
| 2005 | 787.80 | 787.81 |
| 2009 | 639.29 | 639.30 |

Na segunda coluna, `ROUND` está **dentro** de `SUM`: cada item é arredondado antes de entrar na soma. Na primeira, `ROUND` está **fora**: a soma é feita com os valores exatos, e só o resultado é arredondado.

A diferença de um centavo na venda 2009 vem de dois itens:

| produto_id | Valor exato | Valor arredondado | Diferença |
|---|---|---|---|
| 5 | 64.84500 | 64.85 | +0.00500 |
| 10 | 142.40000 | 142.40 | 0 |
| 6 | 29.12950 | 29.13 | +0.00050 |
| 7 | 402.92000 | 402.92 | 0 |

Os dois arredondamentos empurram o valor para cima, e juntos acrescentam `0.0055` ao total. O total exato, `639.2945`, arredonda para `639.29`. A soma dos itens arredondados dá `639.30`.

Nenhuma das duas formas é erro do SGBD. Cada uma responde a uma pergunta. Arredondar no final dá o valor mais próximo do exato. Arredondar por item reproduz o que costuma constar de um documento de venda, em que cada item aparece com o seu valor em centavos e o total é a soma desses valores. A escolha é uma regra do minimundo, e precisa ser enunciada.

O valor `64.845` ilustra ainda o comportamento de `ROUND` diante de um empate: quando o dígito descartado é exatamente 5, o PostgreSQL arredonda o tipo `NUMERIC` para longe do zero, e `64.845` torna-se `64.85`.

**Regra de boa prática:** decidir se o arredondamento acontece por item ou no total, e aplicar a mesma decisão em todas as consultas. Dois relatórios que diferem em um centavo levantam a suspeita de que um deles está errado, mesmo quando ambos estão certos.

---

## 7. Agregação por produto

### 7.1 A consulta

```sql
-- Quantidade vendida, faturamento e valor medio de cada produto
SELECT
    produto_id,
    SUM(quantidade)                                              AS qtd_total,
    ROUND(SUM(quantidade * valor_unitario), 2)                   AS total_vendas,
    ROUND(SUM(quantidade * valor_unitario) / SUM(quantidade), 2) AS valor_medio,
    unidade
FROM
    vendas_itens2
GROUP BY
    produto_id,
    unidade
ORDER BY
    total_vendas DESC;
```

Resultado completo, dez linhas:

| produto_id | qtd_total | total_vendas | valor_medio | unidade |
|---|---|---|---|---|
| 1 | 10.000 | 1533.25 | 153.33 | UN |
| 4 | 7.000 | 1529.90 | 218.56 | UN |
| 7 | 6.000 | 1208.08 | 201.35 | UN |
| 9 | 13.000 | 1183.81 | 91.06 | UN |
| 2 | 7.000 | 699.30 | 99.90 | UN |
| 10 | 65.000 | 604.80 | 9.30 | UN |
| 5 | 16.894 | 219.28 | 12.98 | Kg |
| 6 | 3.242 | 119.04 | 36.72 | Kg |
| 3 | 2.552 | 117.81 | 46.16 | Kg |
| 8 | 3.088 | 104.80 | 33.94 | Kg |

### 7.2 Três colunas, três perguntas

| Coluna | Pergunta respondida |
|---|---|
| `qtd_total` | Quanto do produto foi vendido, na unidade de medida dele |
| `total_vendas` | Quanto a loja recebeu pelo produto |
| `valor_medio` | Quanto a loja recebeu, em média, por unidade de medida vendida |

Lidas juntas, as colunas mostram coisas que nenhuma delas mostra sozinha. O produto 10 vendeu 65 unidades e rendeu `604.80`. O produto 4 vendeu 7 unidades e rendeu `1529.90`. Os produtos 1 e 4 têm faturamentos quase iguais, com quantidades e preços muito diferentes.

O `ORDER BY` usa o alias `total_vendas`, o que é permitido porque a ordenação é feita depois do `SELECT`, conforme a ordem lógica estabelecida no arquivo 02.

### 7.3 Por que `unidade` está no `GROUP BY`

A coluna `unidade` aparece na lista do `SELECT` sem estar dentro de uma função de agregação, e por isso precisa constar do `GROUP BY`. O acréscimo não altera os grupos, porque cada produto tem uma única unidade de medida, pela regra 5.

O SGBD não conhece a regra 5. Para ele, `unidade` poderia variar dentro de um mesmo produto. Se uma das linhas do produto 3 tivesse sido gravada com `'kg'`, em minúsculas, o produto 3 apareceria em duas linhas do resultado, uma para cada grafia, cada qual com uma parte das quantidades e dos valores.

A alternativa de escrever `MAX(unidade)` e retirar a coluna do `GROUP BY` também seria aceita, e esconderia o problema: o SGBD escolheria uma das grafias e somaria tudo em uma linha só. Manter a coluna no agrupamento tem a vantagem de expor a inconsistência em vez de escondê-la.

### 7.4 Somar quantidades de unidades diferentes

```sql
SELECT
    SUM(quantidade) AS quantidade_total
FROM
    vendas_itens2;
```

| quantidade_total |
|---|
| 133.776 |

O número é calculado sem erro e não significa nada. Ele soma 108 peças de produtos contados com 25,776 quilogramas de produtos pesados. Para o SGBD, `quantidade` é apenas um número, e a unidade de medida é outra coluna, que ele não relaciona com esta.

A versão com significado separa as grandezas:

```sql
SELECT
    unidade,
    COUNT(*)        AS itens,
    SUM(quantidade) AS quantidade_total
FROM
    vendas_itens2
GROUP BY
    unidade
ORDER BY
    unidade;
```

| unidade | itens | quantidade_total |
|---|---|---|
| Kg | 18 | 25.776 |
| UN | 32 | 108.000 |

A coluna `qtd_total` da seção 7.1 tem significado pela mesma razão. Cada grupo é um produto, e dentro de um produto todas as quantidades estão na mesma unidade. É o `GROUP BY` que dá sentido à soma.

**Regra de boa prática:** somar uma coluna de quantidade apenas dentro de grupos de mesma unidade de medida. O SGBD soma quilogramas com peças sem protestar.

### 7.5 Média simples e média ponderada

A coluna `valor_medio` da seção 7.1 não foi calculada com `AVG`. Ela divide o faturamento pela quantidade vendida, e o resultado é uma **média ponderada**: cada preço pesa conforme a quantidade vendida a esse preço. `AVG(valor_unitario)` calcula a média simples, em que cada item pesa o mesmo, qualquer que seja a quantidade.

```sql
SELECT
    produto_id,
    unidade,
    ROUND(AVG(valor_unitario), 2)                                AS media_simples,
    ROUND(SUM(quantidade * valor_unitario) / SUM(quantidade), 2) AS media_ponderada
FROM
    vendas_itens2
GROUP BY
    produto_id,
    unidade
ORDER BY
    produto_id;
```

Resultado completo, dez linhas:

| produto_id | unidade | media_simples | media_ponderada |
|---|---|---|---|
| 1 | UN | 153.92 | 153.33 |
| 2 | UN | 99.90 | 99.90 |
| 3 | Kg | 46.34 | 46.16 |
| 4 | UN | 219.24 | 218.56 |
| 5 | Kg | 12.97 | 12.98 |
| 6 | Kg | 37.00 | 36.72 |
| 7 | UN | 201.32 | 201.35 |
| 8 | Kg | 33.84 | 33.94 |
| 9 | UN | 90.89 | 91.06 |
| 10 | UN | 9.18 | 9.30 |

O produto 10 mostra a diferença com clareza. Seus cinco itens:

| venda_id | quantidade | valor_unitario | Valor do item |
|---|---|---|---|
| 2001 | 20.000 | 10.00 | 200.00 |
| 2004 | 12.000 | 9.50 | 114.00 |
| 2006 | 8.000 | 9.10 | 72.80 |
| 2009 | 16.000 | 8.90 | 142.40 |
| 2014 | 9.000 | 8.40 | 75.60 |

A média simples soma os cinco preços e divide por cinco: `45.90 / 5 = 9.18`. A média ponderada divide o faturamento pelas unidades vendidas: `604.80 / 65`, aproximadamente `9.30`. A maior quantidade, vinte unidades, foi vendida ao maior preço, e a média ponderada dá a esse preço o peso de vinte unidades, enquanto a simples lhe dá o peso de um item.

O produto 2 tem as duas médias iguais, e não por acaso. Quando todos os preços são iguais, qualquer ponderação produz o mesmo resultado.

As duas médias respondem a perguntas diferentes. A simples responde qual foi o preço típico nas vendas em que o produto apareceu. A ponderada responde quanto a loja recebeu, em média, por unidade vendida. Para análise de faturamento, a pergunta é quase sempre a segunda.

### 7.6 A divisão entre somas

Na expressão `SUM(quantidade * valor_unitario) / SUM(quantidade)`, as duas somas são calculadas para o grupo, e só então uma é dividida pela outra. A quantidade de casas decimais do quociente é escolhida pelo SGBD, como no caso de `AVG`, e por isso a expressão inteira passa por `ROUND`.

O quociente do produto 1 é exatamente `1533.25 / 10 = 153.325`, e `ROUND` o leva a `153.33`, pela regra do empate vista na seção 6.3.

A divisão tem um risco. Se a soma das quantidades de algum grupo fosse zero, a consulta inteira falharia com:

```
ERROR:  division by zero
```

A falha não afetaria apenas a linha daquele produto: nenhuma linha seria devolvida. Neste cenário ela é impossível somente porque todas as quantidades são positivas, e isso é a regra 4, enunciada e não declarada. Uma quantidade zero inserida por engano no único item de um produto derrubaria o relatório de todos os produtos. É um exemplo concreto do valor de uma restrição declarada, assunto do roteiro prático 01.

---

## 8. Boas práticas consolidadas

As regras abaixo acrescentam-se às do arquivo 03, seção 10, e referem-se ao que este arquivo introduziu.

### 8.1 Definição de dados

| Regra | Razão |
|---|---|
| Escala de `NUMERIC` escolhida pela menor fração que o minimundo registra | Casas decimais em excesso são arredondadas na inserção, sem erro |
| Quantidade em `NUMERIC` quando a grandeza se fraciona | Uma coluna `INTEGER` transforma `0.450` em `0` sem avisar |
| Unidade de medida registrada junto da quantidade | Um número sem unidade não pode ser somado com segurança |
| Atributo derivado calculado na consulta, enquanto não houver razão para armazená-lo | Um valor armazenado ao lado dos valores de que depende pode divergir deles |
| Códigos em texto escritos sempre com a mesma grafia | `'Kg'` e `'kg'` formam grupos diferentes |
| Nome de tabela que diga o que ela contém | Um sufixo numérico não informa o que distingue uma tabela da outra |

### 8.2 Escrita de consultas

| Regra | Razão |
|---|---|
| Valor de um conjunto de itens como `SUM(quantidade * valor_unitario)` | Cada item contribui com a quantidade vendida multiplicada pelo seu preço |
| A função de agregação envolve a expressão inteira | O produto das somas não é a soma dos produtos |
| Somar quantidades apenas em grupos de mesma unidade | Quilogramas e peças não se somam |
| Média ponderada para preço médio por unidade vendida | `AVG` dá o mesmo peso a um item de vinte unidades e a um item de uma |
| Uma única regra de arredondamento, por item ou no total | As duas formas divergem em centavos |
| Manter no `GROUP BY` a coluna que depende do grupo, em vez de escondê-la com `MAX` | Uma grafia divergente aparece como uma linha a mais |

O tratamento estendido está em `referencia/04-boas-praticas-sql.md`, e os critérios de escolha de tipo em `referencia/01-tipos-de-dados.md`.

---

## 9. Erros frequentes e leitura das mensagens

| Mensagem ou sintoma | Causa | Correção |
|---|---|---|
| `relation "vendas_itens2" does not exist` | Conexão apontando para `bd_aula` | Conferir a linha `-- Active:` e a conexão selecionada |
| `column "vendas_itens2.unidade" must appear in the GROUP BY clause` | `unidade` na lista do `SELECT` sem estar no `GROUP BY` | Acrescentá-la ao `GROUP BY` |
| `division by zero` | Um grupo com soma de quantidades igual a zero | Conferir os dados. A regra que proíbe quantidade zero ainda não está declarada |
| `numeric field overflow` | Quantidade com mais de sete dígitos à esquerda da vírgula | Conferir o dado ou a precisão declarada |
| `column "total_vendas" does not exist` | Alias usado em `WHERE` ou em `HAVING` | Repetir a expressão |
| Quantidade armazenada diferente da informada, sem erro | Mais casas decimais do que a escala da coluna | Rever a escala declarada |
| Resultado com cinco casas decimais | Produto de um número de escala 3 por um de escala 2 | `ROUND` na apresentação |
| Total de venda que ignora a quantidade, sem erro | A expressão somada omitiu a coluna `quantidade` | Somar `quantidade * valor_unitario` |
| Soma de quantidades sem significado | Unidades de medida diferentes no mesmo grupo | Agrupar pela unidade |
| Um centavo de diferença entre dois relatórios | Arredondamento por item em um e no total no outro | Unificar a regra de arredondamento |
| Um produto aparece em duas linhas do agrupamento | Grafias diferentes da unidade, como `'Kg'` e `'kg'` | Corrigir os dados |

Das onze linhas, seis descrevem resultado inesperado sem mensagem de erro. Todas decorrem de o SGBD tratar a quantidade como número, sem conhecer a grandeza que ela mede nem as regras que o minimundo impõe a ela.

---

## 10. Script consolidado

Todo o código do arquivo, na ordem de execução.

```sql
-- ===============================================================
-- Conexao: bd_vendas, esquema public
-- ===============================================================
-- Active: 1787177433004@@127.0.0.1@5432@bd_vendas@public

-- ---------------------------------------------------------------
-- 1. Estrutura
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS vendas_itens2;

CREATE TABLE vendas_itens2 (
    id             INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    venda_id       INTEGER       NOT NULL,
    produto_id     INTEGER       NOT NULL,
    quantidade     NUMERIC(10,3) NOT NULL,
    unidade        TEXT          NOT NULL,
    valor_unitario NUMERIC(10,2) NOT NULL,
    data_venda     DATE          NOT NULL
);

-- Esquema criado, instancia vazia: sete colunas, nenhuma linha
SELECT * FROM vendas_itens2;

-- ---------------------------------------------------------------
-- 2. Carga
-- ---------------------------------------------------------------
INSERT INTO vendas_itens2 (venda_id, produto_id, quantidade, unidade, valor_unitario, data_venda) VALUES
-- Cinco vendas com cinco itens cada (venda_id 2001 a 2005)
(2001,  1,  1.000, 'UN', 150.55, '2025-09-01'),
(2001,  3,  0.450, 'Kg',  45.00, '2025-09-01'),
(2001,  5,  3.450, 'Kg',  12.75, '2025-09-01'),
(2001,  9,  2.000, 'UN',  88.78, '2025-09-01'),
(2001, 10, 20.000, 'UN',  10.00, '2025-09-01'),

(2002,  2,  1.000, 'UN',  99.90, '2025-09-02'),
(2002,  4,  1.000, 'UN', 225.00, '2025-09-02'),
(2002,  6,  0.874, 'Kg',  35.00, '2025-09-02'),
(2002,  8,  0.895, 'Kg',  34.50, '2025-09-02'),
(2002,  1,  2.000, 'UN', 150.55, '2025-09-02'),

(2003,  7,  1.000, 'UN', 199.99, '2025-09-03'),
(2003,  9,  3.000, 'UN',  89.15, '2025-09-03'),
(2003,  3,  0.860, 'Kg',  46.15, '2025-09-03'),
(2003,  2,  1.000, 'UN',  99.90, '2025-09-03'),
(2003,  5,  2.150, 'Kg',  12.80, '2025-09-03'),

(2004,  4,  1.000, 'UN', 220.00, '2025-09-04'),
(2004,  6,  0.978, 'Kg',  35.00, '2025-09-04'),
(2004,  1,  1.000, 'UN', 155.65, '2025-09-04'),
(2004,  7,  1.000, 'UN', 200.26, '2025-09-04'),
(2004, 10, 12.000, 'UN',   9.50, '2025-09-04'),

(2005,  8,  0.750, 'Kg',  35.90, '2025-09-05'),
(2005,  9,  1.000, 'UN',  90.85, '2025-09-05'),
(2005,  2,  2.000, 'UN',  99.90, '2025-09-05'),
(2005,  3,  0.720, 'Kg',  46.15, '2025-09-05'),
(2005,  4,  2.000, 'UN', 218.50, '2025-09-05'),

-- Quatro vendas com quatro itens cada (venda_id 2006 a 2009)
(2006,  1,  3.000, 'UN', 150.55, '2025-09-06'),
(2006,  5,  3.784, 'Kg',  12.95, '2025-09-06'),
(2006,  9,  1.000, 'UN',  90.85, '2025-09-06'),
(2006, 10,  8.000, 'UN',   9.10, '2025-09-06'),

(2007,  7,  1.000, 'UN', 201.46, '2025-09-07'),
(2007,  6,  0.645, 'Kg',  38.90, '2025-09-07'),
(2007,  8,  0.789, 'Kg',  33.45, '2025-09-07'),
(2007,  2,  2.000, 'UN',  99.90, '2025-09-07'),

(2008,  3,  0.225, 'Kg',  47.20, '2025-09-08'),
(2008,  4,  1.000, 'UN', 217.50, '2025-09-08'),
(2008,  1,  1.000, 'UN', 158.10, '2025-09-08'),
(2008,  9,  2.000, 'UN',  92.85, '2025-09-08'),

(2009,  5,  4.950, 'Kg',  13.10, '2025-09-09'),
(2009, 10, 16.000, 'UN',   8.90, '2025-09-09'),
(2009,  6,  0.745, 'Kg',  39.10, '2025-09-09'),
(2009,  7,  2.000, 'UN', 201.46, '2025-09-09'),

-- Duas vendas com dois itens cada (venda_id 2010 e 2011)
(2010,  2,  1.000, 'UN',  99.90, '2025-09-10'),
(2010,  3,  0.297, 'Kg',  47.20, '2025-09-10'),

(2011,  8,  0.654, 'Kg',  31.50, '2025-09-11'),
(2011,  9,  4.000, 'UN',  92.85, '2025-09-11'),

-- Cinco vendas com um item cada (venda_id 2012 a 2016)
(2012,  4,  2.000, 'UN', 215.20, '2025-09-12'),
(2013,  1,  2.000, 'UN', 158.10, '2025-09-13'),
(2014, 10,  9.000, 'UN',   8.40, '2025-09-14'),
(2015,  5,  2.560, 'Kg',  13.25, '2025-09-15'),
(2016,  7,  1.000, 'UN', 203.45, '2025-09-16');

-- Conferencia: 50 linhas
SELECT * FROM vendas_itens2;

-- ---------------------------------------------------------------
-- 3. Recuperacao sobre o novo cenario
-- ---------------------------------------------------------------
-- Vendas em que o produto 1 aparece
SELECT
    venda_id,
    quantidade,
    unidade,
    valor_unitario,
    data_venda
FROM
    vendas_itens2
WHERE
    produto_id = 1;

-- Todas as informacoes da venda 2001
SELECT
    *
FROM
    vendas_itens2
WHERE
    venda_id = 2001;

-- ---------------------------------------------------------------
-- 4. O valor de um item
-- ---------------------------------------------------------------
SELECT
    venda_id,
    produto_id,
    quantidade,
    unidade,
    valor_unitario,
    quantidade * valor_unitario AS valor_item
FROM
    vendas_itens2
WHERE
    venda_id = 2001;

SELECT
    venda_id,
    produto_id,
    quantidade,
    unidade,
    valor_unitario,
    ROUND(quantidade * valor_unitario, 2) AS valor_item
FROM
    vendas_itens2
WHERE
    venda_id = 2001;

-- ---------------------------------------------------------------
-- 5. Agregacao sobre expressoes: o total de cada venda
-- ---------------------------------------------------------------
-- Valor da venda 2001
SELECT
    SUM(quantidade * valor_unitario) AS valor_total
FROM
    vendas_itens2
WHERE
    venda_id = 2001;

-- Valor total de cada venda
SELECT
    venda_id,
    SUM(quantidade * valor_unitario) AS valor_total_venda,
    data_venda
FROM
    vendas_itens2
GROUP BY
    venda_id,
    data_venda
ORDER BY
    data_venda;

-- Arredondar no total contra arredondar por item
SELECT
    venda_id,
    ROUND(SUM(quantidade * valor_unitario), 2) AS total_arredondado,
    SUM(ROUND(quantidade * valor_unitario, 2)) AS soma_dos_itens_arredondados
FROM
    vendas_itens2
WHERE
    venda_id IN (2005, 2009)
GROUP BY
    venda_id
ORDER BY
    venda_id;

-- ---------------------------------------------------------------
-- 6. Agregacao por produto
-- ---------------------------------------------------------------
-- Quantidade vendida, faturamento e valor medio de cada produto
SELECT
    produto_id,
    SUM(quantidade)                                              AS qtd_total,
    ROUND(SUM(quantidade * valor_unitario), 2)                   AS total_vendas,
    ROUND(SUM(quantidade * valor_unitario) / SUM(quantidade), 2) AS valor_medio,
    unidade
FROM
    vendas_itens2
GROUP BY
    produto_id,
    unidade
ORDER BY
    total_vendas DESC;

-- Soma de quantidades sem significado
SELECT
    SUM(quantidade) AS quantidade_total
FROM
    vendas_itens2;

-- Soma de quantidades por unidade de medida
SELECT
    unidade,
    COUNT(*)        AS itens,
    SUM(quantidade) AS quantidade_total
FROM
    vendas_itens2
GROUP BY
    unidade
ORDER BY
    unidade;

-- Media simples contra media ponderada
SELECT
    produto_id,
    unidade,
    ROUND(AVG(valor_unitario), 2)                                AS media_simples,
    ROUND(SUM(quantidade * valor_unitario) / SUM(quantidade), 2) AS media_ponderada
FROM
    vendas_itens2
GROUP BY
    produto_id,
    unidade
ORDER BY
    produto_id;
```

---

## 11. Exercícios

Os enunciados devem ser resolvidos sem consultar a seção 12. Cada resposta deve ser escrita por inteiro.

**Minimundo e tipos**

1. A regra 4 diz que a quantidade é sempre maior que zero. Explicar o que acontece com a consulta da seção 7.1 em duas situações: se **um** item do produto 8 tiver sido gravado com quantidade `0.000`, e se **todos** os itens do produto 8 tiverem sido gravados assim.
2. Explicar por que a coluna `quantidade` foi declarada `NUMERIC(10,3)` e não `INTEGER`, e calcular o valor da venda 2010 caso ela tivesse sido declarada `INTEGER`.
3. Supondo a coluna `quantidade` declarada como `NUMERIC(10,2)`, indicar o valor que seria armazenado para as quantidades `0.874` e `0.225`, e calcular o valor do item de `0.225` quilograma do produto 3, vendido a `47.20`, nas duas escalas.
4. Indicar qual coluna de `vendas_itens2` armazena repetidamente um fato que pertence ao produto, e qual armazena repetidamente um fato que pertence à venda. Explicar por que `valor_unitario`, que também se repete, não está na mesma situação.

**Recuperação e expressões**

5. Listar `venda_id`, `produto_id`, `quantidade` e o valor do item arredondado a duas casas, chamado `valor_item`, apenas dos itens vendidos por quilograma, ordenado pelo valor do item em ordem decrescente.
6. Listar os cinco itens de maior valor, com `venda_id`, `produto_id`, `quantidade`, `valor_unitario` e o valor do item.
7. Calcular a quantidade total de quilogramas vendidos pela loja.

**Agregação**

8. Apresentar o valor total de cada venda, arredondado a duas casas, apenas das vendas cujo total passa de 600, ordenado pelo total em ordem decrescente.
9. Reproduzir com uma consulta a tabela de faixa de preço da seção 3.7, com `produto_id`, `unidade`, a quantidade de linhas, o menor e o maior valor unitário, e acrescentar uma coluna com a diferença entre o maior e o menor, chamada `amplitude`.
10. Apresentar, para cada unidade de medida, a quantidade de itens, a quantidade total vendida e o faturamento arredondado a duas casas.
11. Apresentar, em uma única linha, o faturamento total da loja arredondado a duas casas, a quantidade de vendas distintas e o valor médio por venda, também arredondado. Explicar por que o valor médio por venda não é o mesmo que `ROUND(AVG(quantidade * valor_unitario), 2)`.
12. Para as vendas realizadas a partir de 2025-09-10, apresentar a data, a quantidade de itens e o valor total arredondado a duas casas, ordenado pela data.

**Leitura**

13. Explicar, sem executar, por que a consulta abaixo não calcula o valor da venda 2001, e qual número ela devolve.

```sql
SELECT SUM(quantidade) * SUM(valor_unitario) AS total
FROM vendas_itens2
WHERE venda_id = 2001;
```

14. Explicar, a partir dos itens da venda 2005, a diferença de um centavo entre as duas colunas da seção 6.3.
15. Explicar por que, para o produto 10, a média ponderada é maior que a média simples, e por que, para o produto 1, ela é menor.
16. Supor que o item de `id` 3 tenha sido gravado com `'kg'`, em minúsculas, no lugar de `'Kg'`. Descrever o efeito sobre o resultado da consulta da seção 7.1 e sobre uma consulta com `WHERE unidade = 'Kg'`.

---

## 12. Gabarito

**1.** Com **um** item de quantidade zero, a consulta funciona e o resultado não muda. O item acrescenta `0` à soma das quantidades e `0` à soma dos valores, e o valor médio do produto 8 continua `33.94`. Uma média simples com `AVG(valor_unitario)`, ao contrário, mudaria, porque o item conta como um preço a mais.

Com **todos** os itens zerados, a soma das quantidades do produto 8 é zero, a divisão falha com `division by zero`, e a consulta inteira é interrompida. Nenhum produto aparece no resultado, e não apenas o produto 8. A regra 4 é enunciada e não declarada, e a restrição que a tornaria impossível de violar é tratada no roteiro prático 01.

**2.** A regra 5 inclui produtos vendidos por quilograma, cujas quantidades são frações, como `0.450`. Uma coluna `INTEGER` só representa contagens inteiras. A escala 3 registra a massa com precisão de um grama, conforme a seção 3.3.

A venda 2010 tem dois itens: `1.000` unidade do produto 2 a `99.90` e `0.297` quilograma do produto 3 a `47.20`. Em uma coluna `INTEGER`, a segunda quantidade seria arredondada para `0`, sem erro. O valor da venda seria `1 * 99.90 + 0 * 47.20 = 99.90`, em vez de `113.92`. Os itens de `0.450` e de `0.225` quilograma, nas vendas 2001 e 2008, também seriam zerados.

**3.** `0.874` seria armazenado como `0.87`, e `0.225` como `0.23`.

O item do produto 3 vale `0.225 * 47.20 = 10.62000` na escala 3, e passaria a valer `0.23 * 47.20 = 10.85600`, isto é, `10.86` depois de arredondado. Cinco gramas acrescentados pelo arredondamento da quantidade viraram 24 centavos no valor do item, sem que o SGBD emitisse qualquer aviso.

**4.** `unidade` repete um fato do produto: todos os itens de um mesmo produto têm a mesma unidade. `data_venda` repete um fato da venda: todos os itens de uma mesma venda têm a mesma data.

`valor_unitario` não depende apenas do produto, porque o mesmo produto teve preços diferentes em vendas diferentes, conforme a seção 3.7. Nem apenas da venda, porque a mesma venda tem preços diferentes para produtos diferentes. Depende da combinação dos dois, e por isso pertence ao item, conforme a seção 2.3.

**5.** Itens vendidos por quilograma.

```sql
SELECT
    venda_id,
    produto_id,
    quantidade,
    ROUND(quantidade * valor_unitario, 2) AS valor_item
FROM
    vendas_itens2
WHERE
    unidade = 'Kg'
ORDER BY
    valor_item DESC;
```

Resultado completo, dezoito linhas:

| venda_id | produto_id | quantidade | valor_item |
|---|---|---|---|
| 2009 | 5 | 4.950 | 64.85 |
| 2006 | 5 | 3.784 | 49.00 |
| 2001 | 5 | 3.450 | 43.99 |
| 2003 | 3 | 0.860 | 39.69 |
| 2004 | 6 | 0.978 | 34.23 |
| 2015 | 5 | 2.560 | 33.92 |
| 2005 | 3 | 0.720 | 33.23 |
| 2002 | 8 | 0.895 | 30.88 |
| 2002 | 6 | 0.874 | 30.59 |
| 2009 | 6 | 0.745 | 29.13 |
| 2003 | 5 | 2.150 | 27.52 |
| 2005 | 8 | 0.750 | 26.93 |
| 2007 | 8 | 0.789 | 26.39 |
| 2007 | 6 | 0.645 | 25.09 |
| 2011 | 8 | 0.654 | 20.60 |
| 2001 | 3 | 0.450 | 20.25 |
| 2010 | 3 | 0.297 | 14.02 |
| 2008 | 3 | 0.225 | 10.62 |

O filtro compara com `'Kg'`, com a mesma grafia gravada nos dados. Pela seção 3.4, `'kg'` não devolveria nenhuma linha.

**6.** Os cinco itens de maior valor.

```sql
SELECT
    venda_id,
    produto_id,
    quantidade,
    valor_unitario,
    quantidade * valor_unitario AS valor_item
FROM
    vendas_itens2
ORDER BY
    valor_item DESC
LIMIT
    5;
```

| venda_id | produto_id | quantidade | valor_unitario | valor_item |
|---|---|---|---|---|
| 2006 | 1 | 3.000 | 150.55 | 451.65000 |
| 2005 | 4 | 2.000 | 218.50 | 437.00000 |
| 2012 | 4 | 2.000 | 215.20 | 430.40000 |
| 2009 | 7 | 2.000 | 201.46 | 402.92000 |
| 2011 | 9 | 4.000 | 92.85 | 371.40000 |

O sexto item, com `316.20000`, fica bem abaixo do quinto, e por isso a ordenação por uma única coluna é suficiente para determinar a página. Havendo empate na fronteira do `LIMIT`, seria necessário um critério de desempate, pela regra do arquivo 03, seção 10.2.

**7.** Total de quilogramas.

```sql
SELECT
    SUM(quantidade) AS quilogramas
FROM
    vendas_itens2
WHERE
    unidade = 'Kg';
```

Resultado: `25.776`, isto é, 25 quilogramas e 776 gramas. O filtro é o que dá sentido à soma, pela seção 7.4.

**8.** Vendas acima de 600.

```sql
SELECT
    venda_id,
    ROUND(SUM(quantidade * valor_unitario), 2) AS valor_total
FROM
    vendas_itens2
GROUP BY
    venda_id
HAVING
    SUM(quantidade * valor_unitario) > 600
ORDER BY
    valor_total DESC;
```

Resultado completo, seis linhas:

| venda_id | valor_total |
|---|---|
| 2005 | 787.80 |
| 2004 | 724.14 |
| 2002 | 687.47 |
| 2006 | 664.30 |
| 2009 | 639.29 |
| 2003 | 634.55 |

A condição repete a expressão, porque o alias `valor_total` não pode ser usado em `HAVING`, pela razão exposta no arquivo 03, seção 9.8.

**9.** Faixa de preço por produto.

```sql
SELECT
    produto_id,
    unidade,
    COUNT(*)                                  AS linhas,
    MIN(valor_unitario)                       AS menor,
    MAX(valor_unitario)                       AS maior,
    MAX(valor_unitario) - MIN(valor_unitario) AS amplitude
FROM
    vendas_itens2
GROUP BY
    produto_id,
    unidade
ORDER BY
    produto_id;
```

| produto_id | unidade | linhas | menor | maior | amplitude |
|---|---|---|---|---|---|
| 1 | UN | 6 | 150.55 | 158.10 | 7.55 |
| 2 | UN | 5 | 99.90 | 99.90 | 0.00 |
| 3 | Kg | 5 | 45.00 | 47.20 | 2.20 |
| 4 | UN | 5 | 215.20 | 225.00 | 9.80 |
| 5 | Kg | 5 | 12.75 | 13.25 | 0.50 |
| 6 | Kg | 4 | 35.00 | 39.10 | 4.10 |
| 7 | UN | 5 | 199.99 | 203.45 | 3.46 |
| 8 | Kg | 4 | 31.50 | 35.90 | 4.40 |
| 9 | UN | 6 | 88.78 | 92.85 | 4.07 |
| 10 | UN | 5 | 8.40 | 10.00 | 1.60 |

A coluna `amplitude` é uma expressão entre dois resultados de agregação. As funções são calculadas primeiro, para o grupo, e a subtração é feita depois, sobre os dois valores.

**10.** Por unidade de medida.

```sql
SELECT
    unidade,
    COUNT(*)                                   AS itens,
    SUM(quantidade)                            AS quantidade_total,
    ROUND(SUM(quantidade * valor_unitario), 2) AS faturamento
FROM
    vendas_itens2
GROUP BY
    unidade
ORDER BY
    unidade;
```

| unidade | itens | quantidade_total | faturamento |
|---|---|---|---|
| Kg | 18 | 25.776 | 560.92 |
| UN | 32 | 108.000 | 6759.14 |

**11.** Faturamento total e valor médio por venda.

```sql
SELECT
    ROUND(SUM(quantidade * valor_unitario), 2)                            AS faturamento,
    COUNT(DISTINCT venda_id)                                              AS vendas,
    ROUND(SUM(quantidade * valor_unitario) / COUNT(DISTINCT venda_id), 2) AS valor_medio_venda
FROM
    vendas_itens2;
```

| faturamento | vendas | valor_medio_venda |
|---|---|---|
| 7320.06 | 16 | 457.50 |

O valor médio por venda divide o faturamento pelo número de vendas, 16. `AVG(quantidade * valor_unitario)` divide o mesmo faturamento pelo número de itens, 50, e resulta em `146.40`, que é o valor médio de um item. É a mesma distinção feita no arquivo 03, seção 9.3, entre a média por item e o valor médio de uma venda.

**12.** Vendas a partir de 2025-09-10.

```sql
SELECT
    data_venda,
    COUNT(*)                                   AS itens,
    ROUND(SUM(quantidade * valor_unitario), 2) AS valor_total
FROM
    vendas_itens2
WHERE
    data_venda >= '2025-09-10'
GROUP BY
    data_venda
ORDER BY
    data_venda;
```

Resultado completo, sete linhas:

| data_venda | itens | valor_total |
|---|---|---|
| 2025-09-10 | 2 | 113.92 |
| 2025-09-11 | 2 | 392.00 |
| 2025-09-12 | 1 | 430.40 |
| 2025-09-13 | 1 | 316.20 |
| 2025-09-14 | 1 | 75.60 |
| 2025-09-15 | 1 | 33.92 |
| 2025-09-16 | 1 | 203.45 |

O filtro por data não depende da agregação, e por isso fica no `WHERE`.

**13.** A consulta soma as cinco quantidades da venda, `26.900`, soma os cinco preços, `307.08`, e multiplica um total pelo outro. O resultado é `8260.45200`.

O cálculo multiplica cada quantidade por todos os preços, e não apenas pelo preço do seu próprio item: as vinte unidades do produto 10 são multiplicadas também pelo preço do produto 1, e os 450 gramas do produto 3 pelo preço do produto 9. O valor correto é `SUM(quantidade * valor_unitario)`, que multiplica cada quantidade pelo preço da mesma linha antes de somar, e resulta em `592.34750`.

**14.** Itens da venda 2005:

| produto_id | Valor exato | Valor arredondado | Diferença |
|---|---|---|---|
| 8 | 26.92500 | 26.93 | +0.00500 |
| 9 | 90.85000 | 90.85 | 0 |
| 2 | 199.80000 | 199.80 | 0 |
| 3 | 33.22800 | 33.23 | +0.00200 |
| 4 | 437.00000 | 437.00 | 0 |

A soma exata é `787.80300`, que arredonda para `787.80`. A soma dos valores arredondados é `787.81`, porque os dois arredondamentos acrescentaram juntos `0.007` ao total, o suficiente para mudar o último centavo. O item do produto 8 é um empate, `26.925`, levado para cima pela regra do `ROUND`.

**15.** No produto 10, a maior quantidade, vinte unidades, foi vendida ao maior preço, `10.00`. A média ponderada dá a esse preço o peso de vinte unidades em 65, e por isso fica acima da média simples, que lhe dá o peso de um item em cinco.

No produto 1 ocorre o contrário. Os dois preços mais altos, `158.10` e `155.65`, foram praticados em três itens com quatro unidades no total, enquanto o preço mais baixo, `150.55`, foi praticado em três itens com seis unidades. O preço mais baixo pesa mais na ponderada, que fica em `153.33`, abaixo da simples, `153.92`.

**16.** O item de `id` 3 é o de `3.450` quilogramas do produto 5 na venda 2001. Na consulta da seção 7.1, o produto 5 passaria a ocupar duas linhas: uma para `'Kg'`, com os outros quatro itens, e outra para `'kg'`, com esse item sozinho. Os totais do produto ficariam divididos entre as duas linhas, e nenhuma delas mostraria o produto por inteiro.

A consulta com `WHERE unidade = 'Kg'` deixaria de fora esse item, porque `'kg'` e `'Kg'` são textos diferentes. O total de quilogramas do exercício 7 cairia de `25.776` para `22.326`, sem nenhuma mensagem de erro.

A correção dos dados é feita com `UPDATE`, tratado no roteiro prático 01. A prevenção é uma restrição `CHECK` que limite a coluna aos valores do minimundo, tratada no mesmo roteiro.

---

## 13. Referências

ELMASRI, Ramez. NAVATHE, Shamkant B. *Sistemas de Banco de Dados*. 7. ed. São Paulo: Pearson, 2018. Capítulo 1, seção 1.1, sobre minimundo. Capítulo 3, seção 3.3, sobre atributos derivados. Capítulo 6, seções 6.1 e 6.3, sobre tipos numéricos e a consulta de recuperação. Capítulo 7, seção 7.1, sobre funções de agregação e agrupamento.

POSTGRESQL GLOBAL DEVELOPMENT GROUP. *PostgreSQL 17 Documentation*. Seção *Numeric Types*, sobre precisão, escala e arredondamento na inserção. Disponível em `https://www.postgresql.org/docs/17/datatype-numeric.html`. Seção *Aggregate Functions*. Disponível em `https://www.postgresql.org/docs/17/functions-aggregate.html`.

Material de apoio: `referencia/01-tipos-de-dados.md`, sobre domínios e critérios de escolha de tipo. `referencia/04-boas-praticas-sql.md`, sobre nomenclatura, formatação e scripts reexecutáveis.
