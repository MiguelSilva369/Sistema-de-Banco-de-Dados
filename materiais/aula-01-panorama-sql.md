# Aula 01. Panorama: o ciclo completo em SQL

**Disciplina:** Sistemas de Banco de Dados I. Sistemas de Informação. UNIPAM.
**Item da ementa:** visão geral, anterior ao item 1. Antecipa 4.1, 4.2, 4.3, 4.4 e 7.1.
**Referência:** ELMASRI, R. NAVATHE, S. *Sistemas de Banco de Dados*. 7. ed. São Paulo: Pearson.
**Ambiente:** PostgreSQL 17 em contêiner Docker, acessado pela extensão Database Client.

---

## Sumário

1. Objetivo
2. Escopo e advertência de leitura
3. O minimundo: cursos e alunos
4. Definição das tabelas com `CREATE TABLE`
5. Verificação da estrutura criada
6. Inserção de dados com `INSERT`
7. Consulta de recuperação com `SELECT`
8. Filtro de linhas com `WHERE`
9. Alias de tabela e de coluna
10. Junção de tabelas: visão preliminar
11. Agregação e agrupamento: visão preliminar
12. A ordem lógica de execução
13. Convenções de escrita
14. Script consolidado
15. Exercícios
16. Gabarito
17. Referências

---

## 1. Objetivo

Este documento percorre, em um exemplo mínimo, o caminho que vai da descrição de um recorte do mundo real até a obtenção de respostas a partir dos dados armazenados. O percurso é composto por quatro etapas, correspondentes às quatro funções de um Sistema Gerenciador de Banco de Dados (SGBD):

| Etapa | Descrição | Instrução SQL correspondente |
|---|---|---|
| Definir | Especificar tipos, estruturas e restrições dos dados | `CREATE TABLE` |
| Construir | Armazenar os dados no meio controlado pelo SGBD | `INSERT` |
| Manipular | Consultar os dados armazenados | `SELECT` |
| Compartilhar | Permitir acesso simultâneo de vários usuários e programas | conexão do cliente ao servidor |

O exemplo é deliberadamente pequeno. O interesse não está no tamanho do problema, e sim na compreensão de cada decisão tomada ao longo do caminho.

---

## 2. Escopo e advertência de leitura

O documento apresenta duas categorias de conteúdo, e a distinção entre elas orienta o estudo.

**Conteúdo de domínio imediato.** As seções 4 a 9 tratam de instruções cujo funcionamento é integralmente explicado aqui: `CREATE TABLE`, `INSERT`, `SELECT`, `WHERE`, `ORDER BY` e alias. São a base da linguagem.

**Conteúdo apresentado em caráter preliminar.** As seções 10 e 11 apresentam junção de tabelas e agrupamento com funções de agregação. Esses recursos dependem de fundamentação ainda não construída e aparecem aqui somente para que o panorama do ciclo fique completo. O tratamento formal deles ocorre no item 7.1 da ementa, nos arquivos 25 e 26.

A ordem em que a linguagem é efetivamente construída ao longo da disciplina é a seguinte:

```
consulta simples  ->  operadores  ->  filtros
     ->  alias, ordenacao e apresentacao
     ->  tipos de dados e definicao de tabelas  ->  restricoes
     ->  insercao, atualizacao e remocao
     ->  modelagem conceitual  ->  juncoes  ->  agregacao  ->  subconsultas
```

As seções preliminares deste documento antecipam os três últimos degraus. A antecipação é útil como referência, não como ponto de partida. O estudo sistemático da linguagem começa no arquivo 02.

---

## 3. O minimundo: cursos e alunos

Um banco de dados não representa o mundo inteiro. Representa uma fatia dele, escolhida e delimitada. Essa fatia recebe o nome de **minimundo**, ou universo de discurso.

> **Elmasri, seção 1.1.** O minimundo é a parte do mundo real sobre a qual os dados são armazenados. Toda mudança relevante no minimundo precisa se refletir no banco de dados.

O minimundo adotado é descrito em três regras:

1. A instituição registra os **cursos** que oferece e os **alunos** matriculados.
2. Cada aluno está matriculado em exatamente um curso.
3. Um curso pode existir sem nenhum aluno matriculado.

Cada regra produz uma decisão técnica concreta nas seções seguintes. A terceira tem consequência visível na seção 11.

Importa registrar também o que o minimundo **não** contempla: nota, frequência, data de matrícula, currículo e professor. Nenhum desses dados poderá ser recuperado, porque nenhum deles foi armazenado. Todo dado que se decide não guardar corresponde a uma pergunta que o sistema jamais conseguirá responder.

Representação informal do modelo:

```
curso (1) --------< (N) aluno

curso                       aluno
  id_curso  (identificador)   id_aluno  (identificador)
  nome                        nome
                              id_curso  (referencia ao curso)
```

---

## 4. Definição das tabelas com `CREATE TABLE`

A instrução `CREATE TABLE` pertence à **Linguagem de Definição de Dados** (DDL, *Data Definition Language*). Ela não armazena dado algum. Declara a estrutura que os dados deverão obedecer.

### 4.1 Tabela `curso`

```sql
CREATE TABLE curso(
    id_curso INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(60) NOT NULL UNIQUE
);
```

Análise de cada elemento:

**`curso`**
Nome da tabela. Adotado no singular, em minúsculas, sem acento e sem aspas, pelas razões da seção 13.

**`id_curso INTEGER`**
Coluna destinada a identificar cada curso. O tipo `INTEGER` armazena números inteiros com sinal, na faixa aproximada de menos dois bilhões a mais dois bilhões.

**`GENERATED ALWAYS AS IDENTITY`**
Determina que o valor da coluna seja gerado automaticamente pelo SGBD a cada nova linha, em sequência. A palavra `ALWAYS` impede que a aplicação forneça um valor manualmente, o que protege a sequência contra conflitos. Esta é a forma padronizada pelo SQL:2003. A forma antiga, `SERIAL`, ainda funciona no PostgreSQL, mas não pertence ao padrão da linguagem e não deve ser adotada em código novo.

**`PRIMARY KEY`**
Declara a coluna como **chave primária**. A restrição produz dois efeitos simultâneos: nenhum valor pode se repetir e nenhum valor pode ser nulo. É a chave primária que garante que cada linha seja identificável de forma inequívoca.

**`nome VARCHAR(60)`**
Texto de comprimento variável, limitado a 60 caracteres. O limite não é decorativo. Expressa uma regra sobre o domínio do dado, e a tentativa de gravar um valor mais longo é rejeitada pelo SGBD.

**`NOT NULL`**
Proíbe a ausência de valor. Um curso sem nome não representa nada no minimundo, logo a ausência precisa ser impedida na estrutura, e não apenas na aplicação.

**`UNIQUE`**
Proíbe valores repetidos na coluna. Dois cursos com o mesmo nome seriam indistinguíveis para quem consultasse o sistema. A coluna `nome` é, portanto, uma **chave candidata**: identifica a linha de forma única, embora não tenha sido escolhida como chave primária.

### 4.2 Tabela `aluno`

```sql
CREATE TABLE aluno(
    id_aluno INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(80) NOT NULL,
    id_curso INTEGER NOT NULL REFERENCES curso(id_curso)
);
```

Os elementos novos são dois.

**Ausência de `UNIQUE` em `nome`**
Diferentemente de `curso`, a coluna `nome` de `aluno` admite repetição. Duas pessoas distintas podem ter o mesmo nome, e o modelo precisa refletir o mundo real, não uma conveniência técnica. O contraste demonstra que a escolha de restrições decorre de regras do minimundo, e não de um padrão aplicado mecanicamente.

**`REFERENCES curso(id_curso)`**
Declara `id_curso` como **chave estrangeira**. A restrição estabelece **integridade referencial**: nenhum valor pode ser gravado em `aluno.id_curso` sem que exista uma linha correspondente em `curso.id_curso`. A partir da declaração, o SGBD rejeita aluno vinculado a curso inexistente e impede a remoção de um curso que ainda possua alunos.

A combinação `NOT NULL REFERENCES` expressa a segunda regra do minimundo: todo aluno pertence a um curso, e esse curso precisa existir.

### 4.3 A ordem de criação importa

A tabela `curso` precisa ser criada antes de `aluno`, porque a cláusula `REFERENCES` exige que a tabela referenciada já exista. A execução na ordem inversa produz erro:

```
ERROR:  relation "curso" does not exist
```

A dependência é uma primeira manifestação concreta da integridade referencial: a estrutura de destino precisa existir antes que alguém possa apontar para ela.

---

## 5. Verificação da estrutura criada

Após a execução da DDL, as tabelas existem e estão vazias. A verificação se faz com a consulta mais simples possível:

```sql
SELECT * FROM curso;
SELECT * FROM aluno;
```

O asterisco significa "todas as colunas". O resultado esperado é um conjunto vazio, com os nomes das colunas visíveis no cabeçalho e nenhuma linha abaixo.

O resultado vazio confirma uma distinção conceitual fundamental:

| Conceito | Definição | O que foi executado |
|---|---|---|
| **Esquema** | Descrição da estrutura: tabelas, colunas, tipos e restrições | `CREATE TABLE` |
| **Instância** | Conjunto de dados presentes no banco em um dado momento | ainda nada |

O esquema é estável e muda raramente. A instância muda a cada operação de escrita. A confusão entre os dois origina perguntas como "ao apagar os dados, a tabela desaparece". Não desaparece: `DELETE` atua sobre a instância, `DROP TABLE` atua sobre o esquema. As duas operações têm naturezas e riscos diferentes.

---

## 6. Inserção de dados com `INSERT`

A instrução `INSERT` pertence à **Linguagem de Manipulação de Dados** (DML, *Data Manipulation Language*).

### 6.1 Inserção nos cursos

```sql
INSERT INTO curso (nome) VALUES
('Sistemas de Informacao'),
('Administracao'),
('Direito'),
('Ciencia da Computacao');
```

Observações:

**A coluna `id_curso` não é informada.**
A cláusula `GENERATED ALWAYS AS IDENTITY` impede que um valor seja fornecido para ela. A tentativa de informá-lo produz erro. O SGBD atribui 1, 2, 3 e 4, na ordem de inserção.

**A lista de colunas é explícita.**
Escrever `INSERT INTO curso (nome)` em vez de `INSERT INTO curso` protege o comando contra alterações futuras na ordem ou na quantidade de colunas da tabela.

**Uma única instrução insere quatro linhas.**
A sintaxe de várias listas de valores separadas por vírgula é padrão SQL e reduz o número de idas ao servidor.

**Os textos estão entre aspas simples.**
Em SQL, aspas simples delimitam literais de texto. Aspas duplas têm outro significado, tratado na seção 13.

### 6.2 Inserção nos alunos

```sql
INSERT INTO aluno (nome, id_curso) VALUES
('Ana Breatriz Souza', 1),
('Carlos Henrique Lima', 1),
('Daniela Martins', 2),
('Eduardo Pereira', 3),
('Fernanda Rocha', 1);
```

Aqui a coluna `id_curso` **precisa** ser informada, porque foi declarada `NOT NULL` e não possui valor gerado nem valor padrão.

Os valores 1, 2 e 3 não são arbitrários. Correspondem aos identificadores gerados na inserção anterior, e cada um deles é validado pela restrição de chave estrangeira no momento da gravação. Um valor como 9, inexistente em `curso`, seria rejeitado:

```
ERROR:  insert or update on table "aluno" violates foreign key constraint "aluno_id_curso_fkey"
DETAIL:  Key (id_curso)=(9) is not present in table "curso".
```

A mensagem descreve exatamente o que ocorreu: a operação foi recusada porque a chave não existe na tabela referenciada. A integridade dos dados foi preservada pelo SGBD, sem intervenção da aplicação.

### 6.3 Estado do banco após a inserção

Tabela `curso`:

| id_curso | nome |
|---|---|
| 1 | Sistemas de Informacao |
| 2 | Administracao |
| 3 | Direito |
| 4 | Ciencia da Computacao |

Tabela `aluno`:

| id_aluno | nome | id_curso |
|---|---|---|
| 1 | Ana Breatriz Souza | 1 |
| 2 | Carlos Henrique Lima | 1 |
| 3 | Daniela Martins | 2 |
| 4 | Eduardo Pereira | 3 |
| 5 | Fernanda Rocha | 1 |

Nota relevante para as seções seguintes: o curso 4, `Ciencia da Computacao`, não possui nenhum aluno. A situação é legítima e está prevista na terceira regra do minimundo.

---

## 7. Consulta de recuperação com `SELECT`

A instrução `SELECT` recupera dados. É a instrução mais usada da linguagem e a que possui maior número de cláusulas.

```sql
SELECT
    id_aluno,
    nome,
    id_curso
FROM
    aluno
ORDER BY
    id_aluno ASC;
```

Resultado:

| id_aluno | nome | id_curso |
|---|---|---|
| 1 | Ana Breatriz Souza | 1 |
| 2 | Carlos Henrique Lima | 1 |
| 3 | Daniela Martins | 2 |
| 4 | Eduardo Pereira | 3 |
| 5 | Fernanda Rocha | 1 |

Elementos da consulta:

**`SELECT id_aluno, nome, id_curso`**
Enumera as colunas desejadas. A operação chama-se **projeção**: escolher quais colunas compõem o resultado. Listar as colunas explicitamente é preferível a `SELECT *` em código que será mantido, porque o resultado permanece estável quando novas colunas forem acrescentadas à tabela.

**`FROM aluno`**
Indica a origem das linhas.

**`ORDER BY id_aluno ASC`**
Ordena o resultado. `ASC` produz ordem crescente e é o comportamento padrão, podendo ser omitido. `DESC` produz ordem decrescente.

Um ponto que costuma gerar equívoco: **sem `ORDER BY`, a ordem das linhas retornadas não é garantida**. O fato de um resultado aparecer ordenado sem `ORDER BY` é coincidência decorrente do plano de execução escolhido, não uma promessa do SGBD. Sempre que a ordem for relevante, ela precisa ser declarada.

---

## 8. Filtro de linhas com `WHERE`

A cláusula `WHERE` restringe quais linhas compõem o resultado. A operação chama-se **seleção**, e é distinta da projeção descrita na seção 7: a projeção escolhe colunas, a seleção escolhe linhas.

```sql
SELECT
    nome,
    id_curso
FROM
    aluno
WHERE
    id_curso = 1
ORDER BY
    nome DESC;
```

Resultado:

| nome | id_curso |
|---|---|
| Fernanda Rocha | 1 |
| Carlos Henrique Lima | 1 |
| Ana Breatriz Souza | 1 |

A condição `id_curso = 1` é avaliada linha a linha. Cada linha para a qual a condição resulta em verdadeiro entra no resultado, e as demais são descartadas.

`ORDER BY nome DESC` ordena por texto em ordem decrescente, o que coloca `Fernanda` antes de `Carlos` e `Carlos` antes de `Ana`.

Observa-se que a coluna usada no filtro, `id_curso`, aparece também na projeção. Isso não é obrigatório. A cláusula `WHERE` pode utilizar colunas ausentes do `SELECT`, porque o filtro é aplicado sobre as linhas da origem, e não sobre o resultado já projetado. A seção 12 explica a razão.

O tratamento completo de `WHERE`, com os demais operadores de comparação, ocorre nos arquivos 04 e 06.

---

## 9. Alias de tabela e de coluna

Um **alias** é um nome alternativo atribuído a uma tabela ou a uma coluna dentro de uma consulta.

```sql
SELECT
    c.nome AS curso,
    c.id_curso
FROM
    curso c
WHERE
    nome = 'Sistemas de Informacao';
```

Resultado:

| curso | id_curso |
|---|---|
| Sistemas de Informacao | 1 |

**`curso c`**
Alias de tabela. A tabela `curso` passa a ser referenciável como `c` no restante da consulta. Em consultas de tabela única o ganho é apenas de concisão. Em consultas que envolvem várias tabelas o alias se torna indispensável, porque duas tabelas podem possuir colunas de mesmo nome e o prefixo elimina a ambiguidade.

**`c.nome AS curso`**
Alias de coluna. O cabeçalho da coluna no resultado passa a ser `curso` em vez de `nome`. A palavra `AS` é opcional no PostgreSQL, mas sua omissão prejudica a leitura e não deve ser adotada.

**Onde o alias de coluna pode ser usado**
O alias é atribuído na cláusula `SELECT`, avaliada tardiamente. Por isso ele pode ser referenciado em `ORDER BY`, mas não em `WHERE`. A tentativa a seguir produz erro:

```sql
SELECT nome AS curso
FROM curso
WHERE curso = 'Direito';
```

```
ERROR:  column "curso" does not exist
```

A forma correta repete a expressão original no filtro:

```sql
SELECT nome AS curso
FROM curso
WHERE nome = 'Direito';
```

A razão está na ordem lógica de execução, tratada na seção 12.

**Sobre a grafia dos identificadores**
A consulta escrita em sala continha `c.id_Curso`, com letra maiúscula no meio. O comando funciona, porque o PostgreSQL converte todo identificador não delimitado por aspas para minúsculas antes de resolvê-lo. Ainda assim, a grafia inconsistente deve ser evitada, pelas razões da seção 13.

---

## 10. Junção de tabelas: visão preliminar

> **Conteúdo preliminar.** A junção é tratada formalmente no arquivo 25, depois que o modelo relacional, as restrições e a modelagem conceitual estiverem estabelecidos. O que segue é uma apresentação do problema que a junção resolve.

O resultado da seção 8 tem uma limitação evidente: informa que três alunos pertencem ao curso 1, mas não informa qual é o curso 1. O número é um identificador interno, sem significado para quem lê o relatório.

Os dados necessários existem, distribuídos em duas tabelas. A operação que os combina em um único resultado chama-se **junção** (*join*).

```sql
SELECT
    a.nome AS aluno,
    c.nome AS curso
FROM
    aluno a
    JOIN
        curso c
    ON
        c.id_curso = a.id_curso
ORDER BY
    c.nome;
```

Resultado:

| aluno | curso |
|---|---|
| Daniela Martins | Administracao |
| Eduardo Pereira | Direito |
| Ana Breatriz Souza | Sistemas de Informacao |
| Carlos Henrique Lima | Sistemas de Informacao |
| Fernanda Rocha | Sistemas de Informacao |

Leitura da consulta:

**`FROM aluno a JOIN curso c`**
Declara que o resultado se forma a partir das duas tabelas.

**`ON c.id_curso = a.id_curso`**
Define a condição de correspondência. Para cada linha de `aluno`, o SGBD localiza a linha de `curso` cujo identificador coincide com a chave estrangeira, e produz uma linha combinando as colunas das duas.

**Necessidade do alias**
As duas tabelas possuem coluna chamada `nome`. Sem os prefixos `a.` e `c.`, a consulta seria ambígua e o SGBD recusaria a execução.

**Observação a ser retomada**
O curso `Ciencia da Computacao` não aparece no resultado. Como não possui nenhum aluno, nenhuma linha de `aluno` corresponde a ele, e a forma de junção utilizada descarta linhas sem correspondência. O comportamento é correto para a pergunta formulada, que era sobre alunos, e passa a ser um problema quando a pergunta for sobre cursos. A distinção entre junção interna e junção externa, que resolve exatamente esse caso, é conteúdo do arquivo 25.

---

## 11. Agregação e agrupamento: visão preliminar

> **Conteúdo preliminar.** Funções de agregação, `GROUP BY` e `HAVING` são tratados no arquivo 26.

As consultas anteriores retornam linhas individuais. Uma classe distinta de pergunta exige resumir várias linhas em um único valor, como em "quantos alunos existem em cada curso".

```sql
SELECT
    c.nome AS curso,
    COUNT(a.id_aluno) AS qtd_alunos
FROM
    curso c
    JOIN
        aluno a
    ON
        a.id_curso = c.id_curso
GROUP BY
    c.nome
ORDER BY
    qtd_alunos;
```

Resultado:

| curso | qtd_alunos |
|---|---|
| Administracao | 1 |
| Direito | 1 |
| Sistemas de Informacao | 3 |

Elementos novos:

**`GROUP BY c.nome`**
Reúne em um mesmo grupo todas as linhas que possuem o mesmo valor em `c.nome`. O resultado passa a ter uma linha por grupo, e não mais uma linha por registro.

**`COUNT(a.id_aluno)`**
Função de agregação. Calcula um valor único a partir do conjunto de linhas de cada grupo. Outras funções da mesma família são `SUM`, `AVG`, `MIN` e `MAX`.

**Regra de composição**
Toda coluna que aparece no `SELECT` e não está dentro de uma função de agregação precisa constar do `GROUP BY`. A razão é lógica: se o resultado tem uma linha por grupo, uma coluna que varia dentro do grupo não teria valor único a exibir. A violação da regra produz erro:

```
ERROR:  column "a.nome" must appear in the GROUP BY clause or be used in an aggregate function
```

**`ORDER BY qtd_alunos`**
Aqui o alias definido no `SELECT` pode ser usado, ao contrário do que ocorre em `WHERE`. A explicação está na seção seguinte.

**Ausência novamente observável**
`Ciencia da Computacao` continua fora do resultado, pela mesma razão da seção 10. A pergunta "quantos alunos há em cada curso" tem, para esse curso, a resposta zero, e essa resposta não aparece. Trata-se de um resultado incompleto, cuja correção depende de conteúdo ainda não apresentado.

---

## 12. A ordem lógica de execução

A ordem em que as cláusulas são escritas não é a ordem em que são avaliadas. Compreender essa diferença explica vários comportamentos aparentemente arbitrários da linguagem.

Ordem de escrita:

```
SELECT  ->  FROM  ->  WHERE  ->  GROUP BY  ->  HAVING  ->  ORDER BY
```

Ordem lógica de avaliação:

```
FROM  ->  WHERE  ->  GROUP BY  ->  HAVING  ->  SELECT  ->  ORDER BY
```

| Ordem | Cláusula | Operação realizada |
|---|---|---|
| 1 | `FROM` | Determina a origem das linhas, incluindo junções |
| 2 | `WHERE` | Descarta linhas que não satisfazem a condição |
| 3 | `GROUP BY` | Agrupa as linhas restantes |
| 4 | `HAVING` | Descarta grupos que não satisfazem a condição |
| 5 | `SELECT` | Calcula as expressões e atribui os alias |
| 6 | `ORDER BY` | Ordena o resultado já projetado |

Três consequências decorrem diretamente dessa ordem, e todas foram observadas nas seções anteriores.

**Alias não funciona em `WHERE`, mas funciona em `ORDER BY`.**
O alias nasce na etapa 5. Na etapa 2 ele ainda não existe. Na etapa 6 já existe.

**`WHERE` não aceita função de agregação.**
`WHERE` é avaliado na etapa 2, antes de qualquer agrupamento. Não há grupo sobre o qual calcular. Filtros que dependem de valor agregado pertencem ao `HAVING`, avaliado na etapa 4.

**`WHERE` pode referenciar colunas ausentes do `SELECT`.**
Na etapa 2, todas as colunas da origem estão disponíveis, porque a projeção ainda não ocorreu.

Esta ordem é **lógica**, não física. O otimizador do SGBD é livre para executar as operações em qualquer sequência, desde que o resultado seja idêntico ao da ordem lógica. A ordem lógica descreve o significado da consulta, e não o procedimento de execução.

O assunto é retomado em detalhe no arquivo 02, onde cada etapa é examinada isoladamente.

---

## 13. Convenções de escrita

As convenções a seguir valem para todo o código escrito na disciplina.

### 13.1 Caixa

| Elemento | Caixa | Exemplo |
|---|---|---|
| Palavras reservadas | maiúscula | `SELECT`, `FROM`, `CREATE TABLE`, `NOT NULL` |
| Nomes de tabela e coluna | minúscula, com sublinhado | `aluno`, `id_curso`, `data_matricula` |
| Tipos de dados | maiúscula, de forma consistente | `INTEGER`, `VARCHAR(60)` |

A convenção não é imposta pelo SGBD. O PostgreSQL aceita `select` e `SELECT` indistintamente. Ela existe porque o contraste visual entre a estrutura do comando e os nomes do domínio torna a leitura mais rápida.

### 13.2 Identificadores sem aspas

O PostgreSQL converte para minúsculas todo identificador que não esteja entre aspas duplas. Assim, `id_Curso`, `ID_CURSO` e `id_curso` referem-se à mesma coluna.

Identificadores escritos entre aspas duplas preservam a caixa exatamente como digitada, e passam a exigir aspas em **todas** as referências futuras. Uma coluna criada como `"idCurso"` não pode mais ser referida como `idCurso`, apenas como `"idCurso"`. O uso de aspas cria, portanto, uma obrigação permanente para todo código que venha a tocar aquela tabela.

A recomendação é direta: nomes em minúsculas, com sublinhado, sem acentos e sem aspas.

### 13.3 Palavras reservadas

Certas palavras pertencem à linguagem e não podem ser usadas livremente como nome de tabela ou coluna. `user`, `order`, `group`, `table`, `select` e `check` estão entre elas.

A modelagem em português oferece proteção adicional, porque a maior parte das palavras reservadas é inglesa. `pedido` é seguro, `order` não é. `usuario` é seguro, `user` não é. Adotado o português, ele deve valer para todo o esquema, sem mistura de idiomas.

A lista completa de palavras reservadas consta do material de apoio, em `referencia/04-boas-praticas-sql.md`.

### 13.4 Indentação

Cada cláusula principal em sua própria linha, com os argumentos recuados. O padrão adotado facilita a leitura de consultas longas e torna evidente, na inspeção visual, qual cláusula está ausente.

---

## 14. Script consolidado

```sql
-- =============================================================
-- Aula 01. Panorama do ciclo completo em SQL
-- Minimundo: cursos e alunos
-- =============================================================

-- -------------------------------------------------------------
-- 1. Definicao das tabelas (DDL)
-- -------------------------------------------------------------

CREATE TABLE curso(
    id_curso INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE aluno(
    id_aluno INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(80) NOT NULL,
    id_curso INTEGER NOT NULL REFERENCES curso(id_curso)
);

-- -------------------------------------------------------------
-- 2. Verificacao da estrutura (tabelas vazias)
-- -------------------------------------------------------------

SELECT * FROM curso;
SELECT * FROM aluno;

-- -------------------------------------------------------------
-- 3. Insercao de dados (DML)
-- -------------------------------------------------------------

INSERT INTO curso (nome) VALUES
('Sistemas de Informacao'),
('Administracao'),
('Direito'),
('Ciencia da Computacao');

INSERT INTO aluno (nome, id_curso) VALUES
('Ana Breatriz Souza', 1),
('Carlos Henrique Lima', 1),
('Daniela Martins', 2),
('Eduardo Pereira', 3),
('Fernanda Rocha', 1);

-- -------------------------------------------------------------
-- 4. Consulta de recuperacao com SELECT
-- -------------------------------------------------------------

SELECT
    id_aluno,
    nome,
    id_curso
FROM
    aluno
ORDER BY
    id_aluno ASC;

-- -------------------------------------------------------------
-- 5. Filtro de linhas com WHERE
-- -------------------------------------------------------------

SELECT
    nome,
    id_curso
FROM
    aluno
WHERE
    id_curso = 1
ORDER BY
    nome DESC;

-- -------------------------------------------------------------
-- 6. Alias de tabela e de coluna
-- -------------------------------------------------------------

SELECT
    c.nome AS curso,
    c.id_curso
FROM
    curso c
WHERE
    nome = 'Sistemas de Informacao';

-- -------------------------------------------------------------
-- 7. Juncao de tabelas (conteudo preliminar)
-- -------------------------------------------------------------

SELECT
    a.nome AS aluno,
    c.nome AS curso
FROM
    aluno a
    JOIN
        curso c
    ON
        c.id_curso = a.id_curso
ORDER BY
    c.nome;

-- -------------------------------------------------------------
-- 8. Agregacao e agrupamento (conteudo preliminar)
-- -------------------------------------------------------------

SELECT
    c.nome AS curso,
    COUNT(a.id_aluno) AS qtd_alunos
FROM
    curso c
    JOIN
        aluno a
    ON
        a.id_curso = c.id_curso
GROUP BY
    c.nome
ORDER BY
    qtd_alunos;
```

---

## 15. Exercícios

Os exercícios utilizam as tabelas `curso` e `aluno` com os dados da seção 6.

1. Recuperar todas as colunas de todos os cursos, ordenados pelo nome em ordem crescente.
2. Recuperar apenas o nome dos alunos, ordenados alfabeticamente.
3. Recuperar o identificador e o nome dos alunos cujo identificador seja maior que 2.
4. Recuperar o nome do curso cujo identificador é 3.
5. Recuperar nome e identificador de curso dos alunos que **não** pertencem ao curso 1.
6. Recuperar o nome dos alunos do curso 1, em ordem alfabética crescente, atribuindo ao cabeçalho da coluna o rótulo `aluno_do_curso_um`.
7. Explicar, sem executar, por que a instrução abaixo é recusada pelo SGBD.

   ```sql
   INSERT INTO curso (id_curso, nome) VALUES (10, 'Enfermagem');
   ```

8. Explicar, sem executar, por que a instrução abaixo é recusada pelo SGBD.

   ```sql
   INSERT INTO aluno (nome, id_curso) VALUES ('Helena Dias', 7);
   ```

9. Explicar, sem executar, por que a instrução abaixo é recusada pelo SGBD.

   ```sql
   INSERT INTO curso (nome) VALUES ('Direito');
   ```

10. Determinar, apenas pela leitura, qual o resultado da consulta abaixo e justificar.

    ```sql
    SELECT nome AS curso
    FROM curso
    WHERE curso = 'Direito';
    ```

11. Reescrever a consulta do exercício 10 de forma que ela seja executada com sucesso.

---

## 16. Gabarito

**1.**

```sql
SELECT *
FROM curso
ORDER BY nome ASC;
```

**2.**

```sql
SELECT nome
FROM aluno
ORDER BY nome ASC;
```

**3.**

```sql
SELECT id_aluno, nome
FROM aluno
WHERE id_aluno > 2
ORDER BY id_aluno;
```

**4.**

```sql
SELECT nome
FROM curso
WHERE id_curso = 3;
```

Resultado: `Direito`.

**5.**

```sql
SELECT nome, id_curso
FROM aluno
WHERE id_curso <> 1
ORDER BY nome;
```

O operador `<>` significa "diferente de". A forma `!=` é aceita pelo PostgreSQL e produz o mesmo efeito, mas `<>` é a grafia do padrão SQL.

**6.**

```sql
SELECT nome AS aluno_do_curso_um
FROM aluno
WHERE id_curso = 1
ORDER BY nome ASC;
```

O filtro usa `nome` sem o alias, porque `WHERE` é avaliado antes de o alias existir. A ordenação poderia usar qualquer das duas grafias.

**7.** A coluna `id_curso` foi declarada `GENERATED ALWAYS AS IDENTITY`, o que impede o fornecimento manual de valor.

```
ERROR:  cannot insert a non-DEFAULT value into column "id_curso"
DETAIL:  Column "id_curso" is an identity column defined as GENERATED ALWAYS.
```

**8.** Violação da restrição de chave estrangeira. Não existe curso com `id_curso` igual a 7, e a restrição `REFERENCES curso(id_curso)` impede o vínculo com uma linha inexistente. A integridade referencial é preservada pelo SGBD.

**9.** Violação da restrição `UNIQUE` sobre `curso.nome`. Já existe um curso chamado `Direito`, e a restrição proíbe repetição de valor na coluna.

**10.** A consulta é recusada com `ERROR: column "curso" does not exist`. O alias `curso` é atribuído na etapa 5 da ordem lógica de execução, ao passo que o `WHERE` é avaliado na etapa 2. No momento da avaliação do filtro, o alias ainda não existe, e o SGBD procura uma coluna real com esse nome, que não há.

**11.**

```sql
SELECT nome AS curso
FROM curso
WHERE nome = 'Direito';
```

A expressão original é repetida no `WHERE`, em lugar do alias.

---

## 17. Referências

ELMASRI, Ramez. NAVATHE, Shamkant B. *Sistemas de Banco de Dados*. 7. ed. São Paulo: Pearson, 2018. Capítulos 1, 3 e 6.

POSTGRESQL GLOBAL DEVELOPMENT GROUP. *PostgreSQL 17 Documentation*. Disponível em `https://www.postgresql.org/docs/17/`.
