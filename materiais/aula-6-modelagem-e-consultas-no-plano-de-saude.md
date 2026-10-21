# Roteiro prático 02. Modelagem e consultas no plano de saúde

**Disciplina:** Sistemas de Banco de Dados I. Sistemas de Informação. UNIPAM.
**Itens da ementa:** 3.3, transações e violações de restrição. 5.2 a 5.6, entidades, atributos, chaves, relacionamentos, restrições estruturais, entidade fraca e grau dos relacionamentos. 6.1 e 6.2, subclasses, especialização e generalização. 7.1, consultas com junção, agregação e subconsultas. 7.2, visões. 7.4, operações de conjunto. 8.1 a 8.4, diretrizes de projeto, dependências funcionais e formas normais.
**Referência:** ELMASRI, R. NAVATHE, S. *Sistemas de Banco de Dados*. 7. ed. São Paulo: Pearson. Capítulos 3, 4, 6, 7, 9, 14 e 20.
**Ambiente:** PostgreSQL 17 em contêiner Docker, acessado pela extensão Database Client. Diagrama na extensão Draw.io.
**Cenário:** banco de dados `bd_plano_saude`, de um consultório credenciado a planos de saúde, que atende pacientes de convênios e pacientes particulares.

---

## Sumário

1. Objetivo
2. Preparação
3. Parte 1. O minimundo e o modelo conceitual
4. Parte 2. Do modelo às tabelas
5. Parte 3. A carga e as restrições
6. Parte 4. Consultas com junção
7. Parte 5. Agregação sobre tabelas relacionadas
8. Parte 6. Subconsultas
9. Parte 7. Operações de conjunto
10. Parte 8. Visões
11. Parte 9. Transações
12. Parte 10. A normalização: a planilha do consultório
13. O modelo resultante
14. Erros frequentes e leitura das mensagens
15. Script consolidado
16. Exercícios
17. Gabarito
18. Referências

---

## 1. Objetivo

No roteiro prático 01, o modelo nasceu de uma tabela que já existia: a tabela única do hortifrúti foi desmembrada, e as tabelas resultantes foram ligadas por chaves estrangeiras. Este roteiro percorre o caminho no sentido em que um sistema costuma ser construído. O ponto de partida é o minimundo, descrito em regras. Das regras sai o modelo conceitual, desenhado no Draw.io. Do modelo saem as tabelas, e sobre as tabelas são escritas as consultas.

O cenário é um consultório credenciado a planos de saúde. Ele é pequeno o bastante para caber em uma aula e rico o bastante para exigir quase todos os elementos do modelo entidade-relacionamento: atributos compostos, multivalorados e derivados, relacionamentos de um para muitos e de muitos para muitos, um relacionamento de uma entidade com ela mesma, uma entidade fraca e uma especialização. As mesmas tabelas sustentam, em seguida, as consultas que ainda não foram tratadas: a agregação sobre tabelas relacionadas, as subconsultas, as operações de conjunto, as visões e as transações.

O roteiro é dividido em dez partes, e cada uma depende das anteriores.

| Parte | Assunto | Instruções e conceitos |
|---|---|---|
| 1 | O minimundo e o modelo conceitual | tipos de atributo, chaves, cardinalidade, participação, papéis, entidade fraca, especialização |
| 2 | Do modelo às tabelas | mapeamento do modelo para o relacional, chave composta, autorreferência, `ON DELETE CASCADE` |
| 3 | A carga e as restrições | ordem de inserção, violações de chave primária e estrangeira |
| 4 | Consultas com junção | junção com a superclasse, junção de uma tabela com ela mesma, atributo derivado, junções externas |
| 5 | Agregação sobre tabelas relacionadas | `GROUP BY` e `HAVING` depois da junção |
| 6 | Subconsultas | subconsulta escalar, `IN`, `EXISTS`, `NOT EXISTS`, subconsulta correlacionada |
| 7 | Operações de conjunto | `UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT` |
| 8 | Visões | `CREATE VIEW` e consulta sobre a visão |
| 9 | Transações | `BEGIN`, `COMMIT`, `ROLLBACK` |
| 10 | A normalização | dependência funcional, 1FN, 2FN e 3FN aplicadas à planilha do consultório |

Ao final, os seguintes resultados devem estar assegurados.

| Resultado | Descrição |
|---|---|
| Modelo conceitual | Identificar, em regras escritas, entidades, atributos, chaves, relacionamentos e as suas restrições, e desenhar o diagrama |
| Mapeamento | Transformar cada elemento do diagrama em tabelas, colunas e restrições |
| Consultas | Escrever junções de várias tabelas, inclusive de uma tabela com ela mesma, e agregar sobre o resultado |
| Subconsultas e conjuntos | Responder a perguntas que dependem de outra consulta e combinar resultados de consultas diferentes |
| Visões e transações | Guardar uma consulta como visão e executar um conjunto de instruções como uma unidade |

### 1.1 Delimitação

O roteiro trata as visões apenas na sua forma de consulta guardada, sem atualização por meio da visão. As transações aparecem como unidade de execução, sem os problemas de concorrência entre usuários. A normalização é tratada na Parte 10, sobre uma planilha do consultório, até a terceira forma normal. As formas normais seguintes ficam fora.

---

## 2. Preparação

### 2.1 O banco de dados e o script de trabalho

O banco de dados é criado a partir de uma conexão já existente ao servidor, como foi feito com `bd_vendas` e `bd_hortifruti`.

```sql
CREATE DATABASE bd_plano_saude;
```

Em seguida, cria-se uma conexão ao novo banco na extensão Database Client, e todo o código deste roteiro é escrito em um arquivo novo, `roteiro02.sql`, associado à conexão `bd_plano_saude#public`. A primeira linha do arquivo identifica a conexão.

```sql
-- Active: 1787177433004@@127.0.0.1@5432@bd_plano_saude@public
```

O número depois de `Active:` é gerado pela extensão e varia de uma máquina para outra.

### 2.2 Recomeço

Para recomeçar o roteiro do zero, as visões e as tabelas são removidas na ordem inversa das dependências, e o script é executado de novo desde a Parte 2. Uma tabela só pode ser removida quando nenhuma outra a referencia, e uma visão depende das tabelas que consulta.

```sql
-- Recomeco: primeiro o que depende, depois o que e referenciado
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
```

---

## 3. Parte 1. O minimundo e o modelo conceitual

### 3.1 As regras do minimundo

O consultório registra as suas informações segundo as regras abaixo.

1. Toda pessoa cadastrada tem nome, CPF, data de nascimento e endereço, formado por logradouro, número, bairro e cidade. O CPF não se repete.
2. Uma pessoa pode ter vários telefones, um só ou nenhum.
3. Toda pessoa cadastrada é paciente, médico ou as duas coisas. Um médico do consultório pode também ser atendido como paciente.
4. O paciente tem a data em que foi cadastrado. Um paciente pode ser dependente de outro paciente, o titular do plano. Um titular pode ter vários dependentes, e um dependente tem um único titular.
5. O médico tem um CRM, que não se repete, e uma única especialidade. A lista de especialidades é mantida pelo consultório, e uma especialidade pode ainda não ter médico.
6. O consultório é credenciado a vários convênios. Um médico pode atender por vários convênios, e um convênio pode ter vários médicos. Para cada par de médico e convênio, registra-se a data de início do credenciamento.
7. Cada consulta é de um único paciente, com um único médico, em uma data, e tem um valor. É paga por um único convênio ou é particular. Não existe consulta sem paciente, sem médico, sem data ou sem valor.
8. Em uma consulta, o médico pode solicitar exames. Os exames de uma consulta são numerados a partir de 1. Um exame solicitado só existe como parte da consulta em que foi pedido.
9. A idade do paciente é informada nas consultas, mas não é gravada: ela muda a cada aniversário.

### 3.2 Entidades e atributos

As regras falam de **tipos de entidade**: pessoa, paciente, médico, especialidade, convênio, consulta e exame solicitado. Cada tipo de entidade tem **atributos**, e o Elmasri os classifica segundo três critérios (ELMASRI e NAVATHE, seção 3.3.1).

| Tipo de atributo | Definição | No consultório |
|---|---|---|
| Simples | não se divide em partes com significado próprio | `nome`, `cpf`, `data_nascimento` |
| Composto | formado por partes que têm significado próprio | `endereco`, formado por `logradouro`, `numero`, `bairro` e `cidade` |
| Monovalorado | tem um único valor para cada entidade | `cpf` |
| Multivalorado | pode ter vários valores para a mesma entidade | `telefone`, pela regra 2 |
| Armazenado | é gravado | `data_nascimento` |
| Derivado | é calculado a partir de outro atributo | `idade`, calculada a partir de `data_nascimento`, pela regra 9 |

Um atributo cujo valor não se repete entre as entidades do mesmo tipo é um **atributo-chave**. O CPF é atributo-chave de pessoa, o CRM é atributo-chave de médico, e o nome é atributo-chave de especialidade e de convênio (ELMASRI e NAVATHE, seção 3.3.2).

### 3.3 Relacionamentos e as suas restrições

Um **tipo de relacionamento** associa tipos de entidade. As regras 4 a 7 descrevem os relacionamentos do consultório. Para cada um, duas restrições são lidas nas regras (ELMASRI e NAVATHE, seção 3.4.3). A **razão de cardinalidade** diz com quantas entidades do outro lado uma entidade pode se relacionar: 1:1, 1:N ou N:M. A **participação** diz se toda entidade precisa estar no relacionamento, participação total, ou se pode ficar fora dele, participação parcial.

| Relacionamento | Entidades | Cardinalidade | Participação | Regra |
|---|---|---|---|---|
| POSSUI | ESPECIALIDADE e MEDICO | 1:N | total do médico, parcial da especialidade | 5 |
| CREDENCIADO | MEDICO e CONVENIO | N:M | parcial dos dois lados | 6 |
| REALIZA | PACIENTE e CONSULTA | 1:N | total da consulta, parcial do paciente | 7 |
| ATENDE | MEDICO e CONSULTA | 1:N | total da consulta, parcial do médico | 7 |
| PAGA | CONVENIO e CONSULTA | 1:N | parcial dos dois lados | 7 |
| DEPENDE_DE | PACIENTE e PACIENTE | 1:N | parcial dos dois lados | 4 |
| SOLICITA | CONSULTA e EXAME_SOLICITADO | 1:N | total do exame | 8 |

Três situações merecem atenção.

**Atributo de relacionamento.** A data de início do credenciamento, pela regra 6, não pertence ao médico, que tem uma data para cada convênio, nem ao convênio, que tem uma data para cada médico. Ela pertence ao par, e fica no losango do relacionamento CREDENCIADO, como `quantidade` e `valor_unitario` ficaram no losango CONTÉM do hortifrúti (ELMASRI e NAVATHE, seção 3.4.4).

**Autorrelacionamento e papéis.** DEPENDE_DE liga PACIENTE a PACIENTE. Quando o mesmo tipo de entidade aparece dos dois lados, cada lado recebe um **papel**, que diz a função da entidade no relacionamento: aqui, titular e dependente. Esse tipo de relacionamento é chamado recursivo, ou autorrelacionamento (ELMASRI e NAVATHE, seção 3.4.2).

**Grau do relacionamento.** Uma consulta envolve três entidades ao mesmo tempo: paciente, médico e convênio. O Elmasri discute se esse fato deve ser modelado como um único relacionamento de grau três, ternário, ou como uma entidade ligada às outras três (ELMASRI e NAVATHE, seção 3.9). Como a consulta tem identidade própria, atributos próprios, a data e o valor, e outra entidade depende dela, o exame solicitado, ela é modelada como o tipo de entidade CONSULTA, com três relacionamentos binários de um para muitos. O relacionamento ternário seria adequado se a consulta fosse apenas a combinação dos três, sem identidade nem dependentes.

### 3.4 A entidade fraca

Pela regra 8, o exame solicitado não tem identificador próprio. O exame número 1 existe em várias consultas, e só o par formado pela consulta e pelo número identifica um exame. Um tipo de entidade sem atributo-chave próprio, identificado pela relação com outra entidade, é uma **entidade fraca**. A entidade da qual ela depende é a **entidade proprietária**, aqui CONSULTA, e o atributo que distingue as entidades fracas de um mesmo proprietário é a **chave parcial**, aqui `numero` (ELMASRI e NAVATHE, seção 3.5).

A entidade fraca tem sempre participação total no relacionamento com a proprietária: não existe exame solicitado fora de uma consulta. No diagrama, ela é desenhada com retângulo duplo, o relacionamento que a identifica com losango duplo, e a chave parcial é sublinhada com linha tracejada.

### 3.5 A especialização

Pela regra 1, paciente e médico têm em comum nome, CPF, data de nascimento, endereço e telefones. Pelas regras 4 e 5, cada um tem também atributos e relacionamentos próprios. Esse caso é modelado por uma **superclasse**, PESSOA, com os atributos comuns, e duas **subclasses**, PACIENTE e MEDICO, com os atributos específicos. Toda entidade de uma subclasse é também uma entidade da superclasse e **herda** os seus atributos e relacionamentos (ELMASRI e NAVATHE, seções 4.1 e 4.2).

O processo de definir subclasses a partir de uma superclasse é a **especialização**. O processo inverso, de reunir em uma superclasse o que vários tipos de entidade têm em comum, é a **generalização**. As duas restrições da especialização também são lidas nas regras (ELMASRI e NAVATHE, seção 4.3).

| Restrição | Pergunta | No consultório | Notação |
|---|---|---|---|
| Disjunção | uma entidade pode estar em mais de uma subclasse? | sim, um médico pode ser paciente, pela regra 3: especialização **sobreposta** | letra `o` no círculo |
| Completude | toda entidade da superclasse está em alguma subclasse? | sim, toda pessoa é paciente ou médico, pela regra 3: especialização **total** | linha dupla entre a superclasse e o círculo |

No roteiro prático 01, seção 7.4, a categoria especializou o produto em fruta, legume e verdura. Aquela especialização é disjunta, definida por um atributo, e as subclasses não têm atributos próprios, por isso bastou uma tabela com a coluna `categoria`. Aqui a especialização é sobreposta, e cada subclasse tem atributos e relacionamentos próprios: a data de cadastro e o titular do paciente, o CRM e a especialidade do médico. Por isso cada subclasse terá a sua tabela, como mostra a seção 4.5.

A generalização também pode ser vista neste caso. Se o consultório tivesse começado com um cadastro de pacientes e outro de médicos, cada um com nome, CPF, data de nascimento, endereço e telefones, reunir esses atributos comuns em PESSOA seria uma generalização. O material de 2025 deste mesmo cenário seguiu esse caminho.

### 3.6 O diagrama

O modelo deve ser desenhado no Draw.io, no arquivo `plano-saude.drawio`, na notação usada em sala.

| Elemento | Forma | Atributos |
|---|---|---|
| PESSOA | retângulo | `id`, sublinhado, `nome`, `cpf`, `data_nascimento`, `endereco` composto, ligado a `logradouro`, `numero`, `bairro` e `cidade`, `telefone` em elipse dupla, `idade` em elipse tracejada |
| PACIENTE e MEDICO | retângulos ligados a PESSOA por um círculo com `o`, com linha dupla do lado de PESSOA | PACIENTE: `data_cadastro`. MEDICO: `crm` |
| ESPECIALIDADE, CONVENIO e CONSULTA | retângulos | `id`, sublinhado, e `nome`. CONSULTA: `id`, `data_consulta`, `valor` |
| EXAME_SOLICITADO | retângulo duplo | `numero`, sublinhado tracejado, e `exame` |
| POSSUI, CREDENCIADO, REALIZA, ATENDE, PAGA, DEPENDE_DE | losangos, com 1, N ou M em cada lado e linha dupla do lado de participação total | CREDENCIADO: `data_inicio` |
| SOLICITA | losango duplo | nenhum |

No autorrelacionamento DEPENDE_DE, as duas linhas ligam o losango a PACIENTE, e cada uma recebe o nome do seu papel, titular no lado 1 e dependente no lado N.

---

## 4. Parte 2. Do modelo às tabelas

### 4.1 O procedimento de mapeamento

O Elmasri descreve o mapeamento do modelo entidade-relacionamento para o modelo relacional em passos, aplicados um a um aos elementos do diagrama (ELMASRI e NAVATHE, seções 9.1 e 9.2). A tabela abaixo mostra o resultado de cada passo neste modelo.

| Passo | Elemento do diagrama | Resultado |
|---|---|---|
| 1 | entidade forte | uma tabela por entidade: `pessoa`, `especialidade`, `convenio`, `consulta` |
| 1 | atributo composto | só as partes viram colunas: `logradouro`, `numero`, `bairro`, `cidade` |
| 1 | atributo derivado | nenhuma coluna: a idade é calculada na consulta |
| 2 | entidade fraca | tabela `exame_solicitado`, com a chave da proprietária e a chave parcial formando a chave primária |
| 4 | relacionamento 1:N | chave estrangeira na tabela do lado N: `especialidade_id` em `medico`, `paciente_id`, `medico_id` e `convenio_id` em `consulta`, `titular_id` em `paciente` |
| 5 | relacionamento N:M | tabela própria, `credenciamento`, com uma chave estrangeira para cada lado e o atributo do relacionamento |
| 6 | atributo multivalorado | tabela própria, `telefone`, com a chave da entidade e o valor |
| 8 | especialização | uma tabela para a superclasse e uma para cada subclasse, cuja chave primária é também chave estrangeira para a superclasse |

A participação total vira `NOT NULL` na chave estrangeira, e a parcial, chave estrangeira que aceita nulo, como decidido para `convenio_id`.

### 4.2 A superclasse e os atributos comuns

```sql
-- Regra 1. O endereco composto vira quatro colunas
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
```

A coluna `numero` é `TEXT`, e não `INTEGER`, porque o número de um endereço pode ter letras, como `120A`, e não é usado em cálculo, como os demais identificadores numéricos vistos na aula 03.

### 4.3 O atributo multivalorado

Um telefone não cabe em uma coluna de `pessoa`, porque uma pessoa pode ter vários. Duas colunas, `telefone1` e `telefone2`, limitariam a quantidade e deixariam colunas vazias. Uma lista na mesma célula violaria a primeira forma normal, tratada na Parte 10. O atributo multivalorado vira uma tabela, com uma linha por telefone.

```sql
-- Regra 2. Uma linha por telefone
CREATE TABLE telefone (
    pessoa_id INTEGER NOT NULL REFERENCES pessoa (id),
    numero    TEXT    NOT NULL,
    PRIMARY KEY (pessoa_id, numero)
);
```

A chave primária é **composta**: o par `(pessoa_id, numero)` não se repete, e nenhuma das duas colunas sozinha basta. A mesma pessoa tem vários números, e o mesmo número pode, em tese, pertencer a duas pessoas que moram juntas. Quando a chave primária tem mais de uma coluna, ela é declarada ao final da tabela, como restrição de tabela, e não ao lado de uma coluna (ELMASRI e NAVATHE, seção 6.2.2).

### 4.4 As tabelas sem dependências

```sql
-- Regra 5
CREATE TABLE especialidade (
    id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome TEXT    NOT NULL UNIQUE
);

-- Regra 6
CREATE TABLE convenio (
    id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome TEXT    NOT NULL UNIQUE
);
```

A especialidade é uma tabela, e não um texto em `medico`, pela regra 5: a lista é mantida pelo consultório, e uma especialidade pode existir sem médico. Um texto em `medico` não teria onde registrar uma especialidade ainda sem médico, a mesma anomalia de inserção do pimentão no roteiro prático 01.

### 4.5 As subclasses e o autorrelacionamento

```sql
-- Regras 3 e 4. A chave primaria e tambem chave estrangeira para pessoa
CREATE TABLE paciente (
    pessoa_id     INTEGER PRIMARY KEY REFERENCES pessoa (id),
    data_cadastro DATE    NOT NULL,
    titular_id    INTEGER REFERENCES paciente (pessoa_id)
);

-- Regras 3 e 5
CREATE TABLE medico (
    pessoa_id        INTEGER PRIMARY KEY REFERENCES pessoa (id),
    crm              TEXT    NOT NULL UNIQUE,
    especialidade_id INTEGER NOT NULL REFERENCES especialidade (id)
);
```

Em `paciente` e em `medico`, a coluna `pessoa_id` é ao mesmo tempo chave primária e chave estrangeira. Por ser chave primária, cada pessoa aparece no máximo uma vez em cada subclasse. Por ser chave estrangeira, toda linha de uma subclasse corresponde a uma pessoa que existe. A chave da subclasse não é gerada: é a mesma da superclasse. Como as duas subclasses são tabelas separadas, a mesma pessoa pode estar nas duas, e é assim que a tabela representa a especialização sobreposta.

A coluna `titular_id` referencia a própria tabela `paciente`. É o autorrelacionamento DEPENDE_DE: o dependente guarda a chave do seu titular. A coluna aceita nulo, porque um titular não tem titular, e a participação é parcial. A chave estrangeira de uma tabela para ela mesma segue as mesmas regras das demais: `titular_id` precisa ser a chave de um paciente que existe.

### 4.6 O relacionamento N:M

```sql
-- Regra 6. Uma linha por par de medico e convenio
CREATE TABLE credenciamento (
    medico_id   INTEGER NOT NULL REFERENCES medico (pessoa_id),
    convenio_id INTEGER NOT NULL REFERENCES convenio (id),
    data_inicio DATE    NOT NULL,
    PRIMARY KEY (medico_id, convenio_id)
);
```

O par de chaves estrangeiras é a chave primária: o mesmo médico não pode ser credenciado duas vezes ao mesmo convênio. A estrutura é a de `itens_venda` no roteiro prático 01, a tabela do relacionamento CONTÉM, com uma diferença: lá, o item tinha identificador gerado e a unicidade do par era garantida por `UNIQUE`. Aqui, o próprio par é a chave.

### 4.7 A consulta e a entidade fraca

```sql
-- Regra 7
CREATE TABLE consulta (
    id            INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    paciente_id   INTEGER       NOT NULL REFERENCES paciente (pessoa_id),
    medico_id     INTEGER       NOT NULL REFERENCES medico (pessoa_id),
    convenio_id   INTEGER                REFERENCES convenio (id),
    data_consulta DATE          NOT NULL,
    valor         NUMERIC(10,2) NOT NULL CHECK (valor > 0)
);

-- Regra 8. A chave da proprietaria mais a chave parcial
CREATE TABLE exame_solicitado (
    consulta_id INTEGER NOT NULL REFERENCES consulta (id) ON DELETE CASCADE,
    numero      INTEGER NOT NULL,
    exame       TEXT    NOT NULL,
    PRIMARY KEY (consulta_id, numero)
);
```

A consulta referencia `paciente` e `medico`, e não `pessoa`: só um paciente pode ser atendido, e só um médico pode atender. Uma referência a `pessoa` aceitaria uma consulta em que o médico fosse alguém que não é médico.

A chave primária de `exame_solicitado` reúne a chave da proprietária, `consulta_id`, e a chave parcial, `numero`. A cláusula `ON DELETE CASCADE`, apresentada nos slides da aula anterior, aparece aqui pela primeira vez em uma tabela. Ela expressa a dependência de existência da entidade fraca: se a consulta for excluída, os exames dela são excluídos junto, porque não existem sem ela. No hortifrúti, a mesma cláusula foi recusada, porque apagaria vendas já realizadas. A decisão sobre a ação na exclusão vem, como sempre, do minimundo.

---

## 5. Parte 3. A carga e as restrições

### 5.1 A ordem de inserção

As tabelas são carregadas na ordem das dependências: primeiro `pessoa`, `especialidade` e `convenio`, que não referenciam nenhuma outra, depois as subclasses e os telefones, depois o credenciamento, depois as consultas e, por último, os exames. Como as tabelas acabaram de ser criadas, as chaves geradas seguem a ordem das linhas. As pessoas 1 a 15 são pacientes, as pessoas 16 a 21 são médicos, e a pessoa 17, Beatriz Nascimento, é médica e também paciente.

```sql
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
```

Os pacientes 11 e 12, Lucas Ferreira e Mariana Gomes, são crianças, dependentes de João Silva e de José Santos, e não têm telefone próprio. Laura Mendes, 14, é dependente de Felipe Ribeiro, 13. A especialidade Neurologia ainda não tem médico, e o convênio Nova Saúde ainda não tem consultas.

```sql
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
```

Nas inserções de `paciente`, os dependentes vêm depois dos seus titulares na mesma instrução. A ordem dentro de uma única instrução `INSERT` não importa para o servidor, que confere as chaves estrangeiras ao final da instrução, mas a leitura fica mais simples quando o titular aparece primeiro.

```sql
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
```

Respostas do servidor, na ordem: `INSERT 0 21`, `INSERT 0 22`, `INSERT 0 7`, `INSERT 0 4`, `INSERT 0 16`, `INSERT 0 6`, `INSERT 0 8`, `INSERT 0 20` e `INSERT 0 8`. As consultas recebem os códigos 1 a 20. As consultas 3, 9, 14 e 18 são particulares. A consulta 20 é de Beatriz Nascimento como paciente, atendida por Paulo Araújo.

### 5.2 As restrições em funcionamento

Três instruções devem ser recusadas pelo servidor. A primeira tenta cadastrar de novo um telefone que já existe para a mesma pessoa.

```sql
-- Chave primaria composta
INSERT INTO telefone (pessoa_id, numero)
VALUES (1, '34 99999-0001');
```

```
ERROR:  duplicate key value violates unique constraint "telefone_pkey"
DETAIL:  Key (pessoa_id, numero)=(1, 34 99999-0001) already exists.
```

A mensagem cita as duas colunas da chave: o que se repetiu foi o par, e não o número sozinho. A segunda tenta cadastrar Paulo Araújo, 16, que é médico, também como paciente, dependente de um titular que não existe.

```sql
-- Autorreferencia
INSERT INTO paciente (pessoa_id, data_cadastro, titular_id)
VALUES (16, '2026-10-01', 99);
```

```
ERROR:  insert or update on table "paciente" violates foreign key constraint "paciente_titular_id_fkey"
DETAIL:  Key (titular_id)=(99) is not present in table "paciente".
```

A chave estrangeira de uma tabela para ela mesma é conferida como as demais: o titular 99 precisaria ser um paciente cadastrado. Se o titular fosse informado como `NULL`, a inserção seria aceita, e Paulo Araújo passaria a ser médico e paciente, como Beatriz Nascimento. A terceira instrução exclui um médico da tabela `pessoa`.

```sql
-- Superclasse referenciada
DELETE FROM pessoa
WHERE id = 16;
```

```
ERROR:  update or delete on table "pessoa" violates foreign key constraint "telefone_pessoa_id_fkey" on table "telefone"
DETAIL:  Key (id)=(16) is still referenced from table "telefone".
```

O nome `telefone_pessoa_id_fkey` segue o padrão do servidor para chaves estrangeiras declaradas sem nome: a tabela, a coluna e o sufixo `_fkey`. Paulo Araújo é referenciado pelo seu telefone, pela subclasse `medico`, pelo credenciamento e pelas consultas, e a exclusão é recusada pela primeira referência encontrada.

---

## 6. Parte 4. Consultas com junção

### 6.1 A subclasse e a superclasse

Os atributos de um paciente estão divididos entre duas tabelas: o nome em `pessoa` e a data de cadastro em `paciente`. Toda consulta sobre uma subclasse começa pela junção com a superclasse, pela chave que as duas compartilham.

```sql
SELECT
    pe.nome,
    pa.data_cadastro,
    DATE_PART('year', AGE(CURRENT_DATE, pe.data_nascimento)) AS idade
FROM
    paciente AS pa
    INNER JOIN pessoa AS pe ON pe.id = pa.pessoa_id
ORDER BY
    pe.nome
LIMIT 5;
```

| nome | data_cadastro | idade |
|---|---|---|
| Ana Oliveira | 2026-02-10 | 40 |
| André Moreira | 2026-09-20 | 47 |
| Beatriz Nascimento | 2026-08-01 | 45 |
| Bruno Costa | 2026-06-15 | 35 |
| Carlos Pereira | 2026-03-05 | 34 |

A coluna `idade` é o atributo derivado da regra 9, calculado na consulta. `CURRENT_DATE` devolve a data do dia em que a consulta é executada. `AGE` devolve o intervalo entre duas datas em anos, meses e dias, e `DATE_PART('year', ...)` extrai desse intervalo apenas os anos completos. As idades da tabela foram calculadas em 13/10/2026. Executada em outro dia, a consulta pode devolver idades diferentes, e é exatamente por isso que a idade não é gravada.

### 6.2 Três tabelas: médico, pessoa e especialidade

```sql
SELECT
    pe.nome,
    m.crm,
    e.nome AS especialidade
FROM
    medico AS m
    INNER JOIN pessoa        AS pe ON pe.id = m.pessoa_id
    INNER JOIN especialidade AS e  ON e.id  = m.especialidade_id
ORDER BY
    pe.nome;
```

| nome | crm | especialidade |
|---|---|---|
| Beatriz Nascimento | CRM-MG 1002 | Clínica Geral |
| Camila Rodrigues | CRM-MG 1004 | Pediatria |
| Daniela Alves | CRM-MG 1006 | Oftalmologia |
| Paulo Araújo | CRM-MG 1001 | Cardiologia |
| Thiago Santos | CRM-MG 1005 | Dermatologia |
| Victor Almeida | CRM-MG 1003 | Ortopedia |

### 6.3 A junção de uma tabela com ela mesma

Para listar cada dependente com o nome do seu titular, a tabela `paciente` precisa aparecer duas vezes na mesma consulta, uma no papel de dependente e outra no papel de titular. Cada ocorrência recebe o seu apelido, e o servidor as trata como duas tabelas distintas. Como os nomes estão na superclasse, `pessoa` também aparece duas vezes.

```sql
SELECT
    dep.nome AS dependente,
    tit.nome AS titular
FROM
    paciente AS d
    INNER JOIN pessoa   AS dep ON dep.id = d.pessoa_id
    INNER JOIN paciente AS t   ON t.pessoa_id = d.titular_id
    INNER JOIN pessoa   AS tit ON tit.id = t.pessoa_id
ORDER BY
    dep.nome;
```

| dependente | titular |
|---|---|
| Laura Mendes | Felipe Ribeiro |
| Lucas Ferreira | João Silva |
| Mariana Gomes | José Santos |

Os apelidos `d` e `t` correspondem aos dois papéis do autorrelacionamento. A condição `t.pessoa_id = d.titular_id` liga o dependente ao titular pela chave estrangeira que aponta para a própria tabela. O `INNER JOIN` descarta os pacientes sem titular, que são os próprios titulares. Essa forma de junção é chamada de autojunção (ELMASRI e NAVATHE, seção 7.1.6).

### 6.4 O relacionamento N:M e a entidade fraca

A tabela do relacionamento N:M é consultada com uma junção para cada lado.

```sql
SELECT
    pm.nome AS medico,
    cv.nome AS convenio,
    cr.data_inicio
FROM
    credenciamento AS cr
    INNER JOIN pessoa   AS pm ON pm.id = cr.medico_id
    INNER JOIN convenio AS cv ON cv.id = cr.convenio_id
ORDER BY
    pm.nome,
    cv.nome;
```

| medico | convenio | data_inicio |
|---|---|---|
| Beatriz Nascimento | Amparo Saúde | 2025-01-10 |
| Beatriz Nascimento | Vida Plena | 2023-08-15 |
| Camila Rodrigues | Vida Plena | 2025-05-20 |
| Paulo Araújo | Bem Viver | 2024-03-01 |
| Paulo Araújo | Vida Plena | 2024-03-01 |
| Thiago Santos | Amparo Saúde | 2026-02-01 |
| Victor Almeida | Bem Viver | 2025-02-01 |
| Victor Almeida | Vida Plena | 2024-06-01 |

A junção usa `pessoa` diretamente, sem passar por `medico`, porque `medico_id` já é a chave da pessoa e o nome está em `pessoa`. A passagem por `medico` só seria necessária para usar uma coluna dela, como o CRM. A entidade fraca é consultada pela proprietária.

```sql
SELECT
    c.id AS consulta,
    c.data_consulta,
    es.numero,
    es.exame
FROM
    consulta AS c
    INNER JOIN exame_solicitado AS es ON es.consulta_id = c.id
ORDER BY
    c.id,
    es.numero;
```

| consulta | data_consulta | numero | exame |
|---|---|---|---|
| 1 | 2026-08-03 | 1 | Eletrocardiograma |
| 1 | 2026-08-03 | 2 | Hemograma |
| 3 | 2026-08-05 | 1 | Hemograma |
| 4 | 2026-08-06 | 1 | Radiografia da coluna |
| 7 | 2026-08-11 | 1 | Radiografia do joelho |
| 14 | 2026-08-20 | 1 | Ressonância do joelho |
| 14 | 2026-08-20 | 2 | Hemograma |
| 18 | 2026-08-26 | 1 | Ecocardiograma |

O exame número 1 aparece em cinco consultas: a chave parcial só identifica o exame junto com a consulta.

### 6.5 As junções externas no plano de saúde

Os cinco tipos de junção, apresentados nos slides desta aula com um recorte destas mesmas tabelas, devolvem resultados diferentes entre `consulta` e `convenio` porque há linhas sem correspondência dos dois lados: as quatro consultas particulares e o convênio Nova Saúde.

| Junção de `consulta` com `convenio` | Linhas | O que fica de fora |
|---|---|---|
| `INNER JOIN` | 16 | as consultas particulares e o Nova Saúde |
| `LEFT JOIN` | 20 | o Nova Saúde |
| `RIGHT JOIN` | 17 | as consultas particulares |
| `FULL JOIN` | 21 | nada |
| `CROSS JOIN` | 80 | nada, e quase tudo sem sentido |

O mesmo raciocínio vale para as outras tabelas. Uma pessoa sem telefone só aparece em uma junção com `telefone` se `pessoa` for mantida inteira, com `LEFT JOIN`.

```sql
SELECT
    pe.nome,
    COUNT(t.numero) AS telefones
FROM
    pessoa AS pe
    LEFT JOIN telefone AS t ON t.pessoa_id = pe.id
GROUP BY
    pe.id,
    pe.nome
HAVING
    COUNT(t.numero) <> 1
ORDER BY
    telefones DESC,
    pe.nome;
```

| nome | telefones |
|---|---|
| Ana Oliveira | 2 |
| Beatriz Nascimento | 2 |
| João Silva | 2 |
| Lucas Ferreira | 0 |
| Mariana Gomes | 0 |

O `HAVING` deixa no resultado só as pessoas com zero ou com mais de um telefone, os dois casos que uma coluna `telefone` em `pessoa` não conseguiria representar.

---

## 7. Parte 5. Agregação sobre tabelas relacionadas

### 7.1 Faturamento por convênio

A agregação vista nas aulas 03 e 04 é aplicada agora ao resultado de uma junção. A ordem de execução lógica continua a mesma: primeiro a junção no `FROM`, depois o filtro do `WHERE`, depois os grupos do `GROUP BY` e, por último, o filtro dos grupos no `HAVING`.

```sql
SELECT
    COALESCE(cv.nome, 'Particular') AS convenio,
    COUNT(c.id)                     AS consultas,
    COALESCE(SUM(c.valor), 0)       AS faturamento
FROM
    consulta AS c
    FULL JOIN convenio AS cv ON cv.id = c.convenio_id
GROUP BY
    cv.nome
ORDER BY
    faturamento DESC;
```

| convenio | consultas | faturamento |
|---|---|---|
| Vida Plena | 7 | 1260.00 |
| Particular | 4 | 1150.00 |
| Bem Viver | 5 | 920.00 |
| Amparo Saúde | 4 | 600.00 |
| Nova Saúde | 0 | 0 |

O `FULL JOIN` mantém as consultas particulares e o convênio sem consultas. Para o Nova Saúde, `SUM(c.valor)` devolve nulo, porque não há valor a somar, e o `COALESCE` externo troca o nulo por zero. As quatro consultas particulares formam um único grupo, o de nome nulo, e somam a segunda maior receita do consultório.

### 7.2 Valor médio por especialidade

```sql
SELECT
    e.nome                 AS especialidade,
    COUNT(c.id)            AS consultas,
    ROUND(AVG(c.valor), 2) AS valor_medio
FROM
    especialidade AS e
    INNER JOIN medico   AS m ON m.especialidade_id = e.id
    INNER JOIN consulta AS c ON c.medico_id = m.pessoa_id
GROUP BY
    e.nome
HAVING
    COUNT(c.id) >= 3
ORDER BY
    consultas DESC;
```

| especialidade | consultas | valor_medio |
|---|---|---|
| Cardiologia | 8 | 197.50 |
| Clínica Geral | 6 | 166.67 |
| Ortopedia | 4 | 225.00 |

A especialidade da consulta não está em `consulta`: está no médico, e o nome da especialidade, em `especialidade`. A junção percorre o caminho das chaves estrangeiras, da consulta ao médico e do médico à especialidade. O `HAVING` descarta a Pediatria, que formou um grupo com 2 consultas. Dermatologia, Oftalmologia e Neurologia nem chegam a formar grupo, porque não têm consultas, e o `INNER JOIN` as descartou antes do `GROUP BY`.

---

## 8. Parte 6. Subconsultas

### 8.1 Uma consulta dentro de outra

Algumas perguntas dependem de um valor que só outra consulta conhece. "Quais consultas custaram mais que a média?" exige saber a média antes de filtrar. Uma **subconsulta** é uma instrução `SELECT` escrita entre parênteses dentro de outra instrução, e o seu resultado é usado pela consulta externa (ELMASRI e NAVATHE, seção 7.1.2).

```sql
SELECT
    ROUND(AVG(valor), 2) AS media
FROM
    consulta;
```

| media |
|---|
| 196.50 |

### 8.2 Subconsulta escalar

Quando a subconsulta devolve uma única linha com uma única coluna, ela pode ser usada onde se usaria um valor, como em uma comparação do `WHERE`. É a subconsulta **escalar**.

```sql
SELECT
    c.id,
    c.data_consulta,
    c.valor
FROM
    consulta AS c
WHERE
    c.valor > (SELECT AVG(valor) FROM consulta)
ORDER BY
    c.valor DESC,
    c.id;
```

| id | data_consulta | valor |
|---|---|---|
| 18 | 2026-08-26 | 320.00 |
| 14 | 2026-08-20 | 300.00 |
| 9 | 2026-08-13 | 280.00 |
| 3 | 2026-08-05 | 250.00 |
| 4 | 2026-08-06 | 200.00 |
| 7 | 2026-08-11 | 200.00 |
| 19 | 2026-08-27 | 200.00 |

A subconsulta é executada, devolve 196.50, e a consulta externa compara cada valor com esse número. O resultado não pode ser obtido com `WHERE valor > AVG(valor)`, que o servidor recusa, porque uma função de agregação não pode ser usada no `WHERE`, como visto na aula 03.

### 8.3 Subconsulta com `IN`

Quando a subconsulta devolve uma coluna com várias linhas, ela funciona como uma lista, e o operador `IN`, visto na aula 03, testa se o valor pertence a essa lista.

```sql
-- Pacientes que ja tiveram consulta particular
SELECT
    pe.nome
FROM
    pessoa AS pe
WHERE
    pe.id IN (SELECT paciente_id
              FROM consulta
              WHERE convenio_id IS NULL)
ORDER BY
    pe.nome;
```

| nome |
|---|
| José Santos |
| Mariana Gomes |
| Ricardo Almeida |

A subconsulta devolve 3, 12, 3 e 7, os pacientes das consultas particulares. José Santos aparece uma vez no resultado, embora tenha duas consultas particulares, porque o `IN` só pergunta se o valor está na lista. Uma junção de `pessoa` com `consulta`, com o mesmo filtro, devolveria José Santos duas vezes.

### 8.4 `EXISTS` e `NOT EXISTS`

O operador `EXISTS` recebe uma subconsulta e é verdadeiro quando ela devolve ao menos uma linha. `NOT EXISTS` é verdadeiro quando ela não devolve nenhuma (ELMASRI e NAVATHE, seção 7.1.4). A lista de colunas da subconsulta não importa, e a convenção é escrever `SELECT 1`.

```sql
-- Pacientes que nunca tiveram consulta
SELECT
    pe.nome
FROM
    paciente AS pa
    INNER JOIN pessoa AS pe ON pe.id = pa.pessoa_id
WHERE
    NOT EXISTS (SELECT 1
                FROM consulta AS c
                WHERE c.paciente_id = pa.pessoa_id)
ORDER BY
    pe.nome;
```

| nome |
|---|
| André Moreira |
| Felipe Ribeiro |
| Laura Mendes |

A subconsulta menciona `pa.pessoa_id`, uma coluna da consulta externa. Por isso ela não pode ser executada sozinha: é avaliada de novo para cada paciente da consulta externa, com o valor daquele paciente. Uma subconsulta que depende da linha da consulta externa é chamada **correlacionada** (ELMASRI e NAVATHE, seção 7.1.3). O mesmo resultado foi obtido no roteiro prático 01 com `LEFT JOIN` e `IS NULL`. As duas formas são equivalentes, e o `NOT EXISTS` se lê na mesma ordem da pergunta.

### 8.5 Uma regra que a tabela não garante

A regra 6 diz que um médico atende pelos convênios a que é credenciado. Nenhuma restrição declarada nas tabelas impede uma consulta pelo convênio Bem Viver com um médico que não é credenciado a ele: a chave estrangeira `convenio_id` só exige que o convênio exista. O `NOT EXISTS` permite conferir a regra sobre os dados.

```sql
-- Consultas por convenio com medico nao credenciado a ele
SELECT
    c.id,
    c.medico_id,
    c.convenio_id
FROM
    consulta AS c
WHERE
    c.convenio_id IS NOT NULL
    AND NOT EXISTS (SELECT 1
                    FROM credenciamento AS cr
                    WHERE cr.medico_id   = c.medico_id
                      AND cr.convenio_id = c.convenio_id);
```

| id | medico_id | convenio_id |
|---|---|---|

O resultado vazio confirma que todas as consultas respeitam a regra. Uma linha no resultado indicaria uma consulta a ser corrigida. Regras que as restrições declaradas não alcançam são comuns em sistemas reais, e conferi-las por consulta é uma prática de manutenção dos dados.

### 8.6 Subconsulta correlacionada no `WHERE` e no `SELECT`

A consulta mais cara de cada médico exige comparar cada consulta com o máximo das consultas do mesmo médico. A subconsulta recebe um apelido próprio, `c2`, para distinguir a tabela de dentro da tabela de fora.

```sql
SELECT
    pm.nome AS medico,
    c.id    AS consulta,
    c.valor
FROM
    consulta AS c
    INNER JOIN pessoa AS pm ON pm.id = c.medico_id
WHERE
    c.valor = (SELECT MAX(c2.valor)
               FROM consulta AS c2
               WHERE c2.medico_id = c.medico_id)
ORDER BY
    pm.nome,
    c.id;
```

| medico | consulta | valor |
|---|---|---|
| Beatriz Nascimento | 3 | 250.00 |
| Camila Rodrigues | 9 | 280.00 |
| Paulo Araújo | 18 | 320.00 |
| Victor Almeida | 14 | 300.00 |

As quatro maiores de cada médico são consultas particulares, que custam mais que as consultas pagas por convênio. Uma subconsulta escalar também pode ser usada na lista de colunas do `SELECT`, e, se for correlacionada, é calculada para cada linha do resultado.

```sql
-- Titulares e o numero de dependentes de cada um
SELECT
    pe.nome AS titular,
    (SELECT COUNT(*)
     FROM paciente AS d
     WHERE d.titular_id = pa.pessoa_id) AS dependentes
FROM
    paciente AS pa
    INNER JOIN pessoa AS pe ON pe.id = pa.pessoa_id
WHERE
    pa.titular_id IS NULL
ORDER BY
    dependentes DESC,
    pa.pessoa_id
LIMIT 5;
```

| titular | dependentes |
|---|---|
| João Silva | 1 |
| José Santos | 1 |
| Felipe Ribeiro | 1 |
| Maria Souza | 0 |
| Ana Oliveira | 0 |

### 8.7 `NOT IN` e o nulo

`NOT IN` parece a negação direta de `IN`, mas tem um comportamento diferente quando a lista contém nulo. A consulta abaixo procura os convênios que não aparecem em nenhuma consulta.

```sql
SELECT
    nome
FROM
    convenio
WHERE
    id NOT IN (SELECT convenio_id FROM consulta);
```

| nome |
|---|

O resultado é vazio, e o Nova Saúde, que não tem consultas, não aparece. A lista devolvida pela subconsulta contém o nulo das consultas particulares. Para o Nova Saúde, `4 NOT IN (1, 2, NULL, ...)` equivale a `4 <> 1 AND 4 <> 2 AND 4 <> NULL AND ...`, e a comparação com o nulo não resulta em verdadeiro (ELMASRI e NAVATHE, seção 7.1.1). A condição inteira deixa de ser verdadeira, e a linha é descartada. Com `NOT EXISTS`, a pergunta é feita sobre a existência de linhas, e o nulo não interfere.

```sql
SELECT
    nome
FROM
    convenio AS cv
WHERE
    NOT EXISTS (SELECT 1
                FROM consulta AS c
                WHERE c.convenio_id = cv.id);
```

| nome |
|---|
| Nova Saúde |

**Atenção.** Quando a coluna da subconsulta pode ser nula, a negação deve ser escrita com `NOT EXISTS`, e não com `NOT IN`.

---

## 9. Parte 7. Operações de conjunto

### 9.1 Os resultados como conjuntos

O resultado de uma consulta é um conjunto de linhas, e dois resultados podem ser combinados pelas operações da teoria dos conjuntos: união, interseção e diferença. Em SQL, elas são escritas entre duas instruções `SELECT` com `UNION`, `INTERSECT` e `EXCEPT` (ELMASRI e NAVATHE, seção 6.3.4). As duas consultas precisam ser **compatíveis**: o mesmo número de colunas, na mesma ordem, com tipos compatíveis. Os nomes das colunas do resultado são os da primeira consulta.

### 9.2 `INTERSECT`: médicos que também são pacientes

A especialização sobreposta da seção 3.5 permite que a mesma pessoa esteja em `paciente` e em `medico`. A interseção das duas chaves mostra quem está nas duas subclasses.

```sql
SELECT pessoa_id FROM paciente
INTERSECT
SELECT pessoa_id FROM medico;
```

| pessoa_id |
|---|
| 17 |

A pessoa 17, Beatriz Nascimento, é médica e paciente. A interseção também pode ser usada como subconsulta, para mostrar o nome.

```sql
SELECT
    pe.nome
FROM
    pessoa AS pe
WHERE
    pe.id IN (SELECT pessoa_id FROM paciente
              INTERSECT
              SELECT pessoa_id FROM medico);
```

| nome |
|---|
| Beatriz Nascimento |

### 9.3 `EXCEPT`: pacientes sem consulta

A diferença devolve as linhas da primeira consulta que não estão na segunda.

```sql
SELECT pessoa_id FROM paciente
EXCEPT
SELECT paciente_id FROM consulta
ORDER BY 1;
```

| pessoa_id |
|---|
| 13 |
| 14 |
| 15 |

São Felipe Ribeiro, Laura Mendes e André Moreira, os mesmos da seção 8.4. A coluna do resultado se chama `pessoa_id`, o nome da primeira consulta. O `ORDER BY` vem uma única vez, ao final, e se aplica ao resultado da operação. O número `1` indica a primeira coluna do resultado, porque as duas consultas usam nomes diferentes para ela.

### 9.4 `UNION` e `UNION ALL`

A união reúne as linhas das duas consultas e elimina as repetidas. `UNION ALL` reúne sem eliminar.

```sql
SELECT pessoa_id FROM paciente
UNION
SELECT pessoa_id FROM medico;
```

A consulta devolve 21 linhas, todas as pessoas do cadastro. Com `UNION ALL`, devolveria 22, porque a pessoa 17 apareceria uma vez em cada consulta. A contagem confirma a especialização total da regra 3: toda pessoa está em alguma subclasse, e a união das subclasses tem as mesmas 21 pessoas da superclasse.

| Operação | Linhas | Pessoa 17 |
|---|---|---|
| `paciente UNION medico` | 21 | uma vez |
| `paciente UNION ALL medico` | 22 | duas vezes |
| `paciente INTERSECT medico` | 1 | só ela |
| `paciente EXCEPT medico` | 15 | fora |

---

## 10. Parte 8. Visões

### 10.1 A consulta guardada

A consulta completa de um atendimento envolve seis tabelas: a consulta, o paciente, o médico, a especialidade, o convênio e, duas vezes, a pessoa. Escrevê-la toda vez é trabalhoso e sujeito a erro. Uma **visão** é uma consulta guardada no banco de dados com um nome, que pode ser usada nas consultas como se fosse uma tabela. A visão não guarda dados: a cada uso, o servidor executa a consulta que a define sobre as tabelas atuais. Por isso ela é chamada de tabela virtual (ELMASRI e NAVATHE, seção 7.3).

```sql
CREATE VIEW vw_consulta AS
SELECT
    c.id                            AS consulta,
    c.data_consulta,
    pp.nome                         AS paciente,
    pm.nome                         AS medico,
    e.nome                          AS especialidade,
    COALESCE(cv.nome, 'Particular') AS convenio,
    c.valor
FROM
    consulta AS c
    INNER JOIN pessoa        AS pp ON pp.id = c.paciente_id
    INNER JOIN medico        AS m  ON m.pessoa_id = c.medico_id
    INNER JOIN pessoa        AS pm ON pm.id = m.pessoa_id
    INNER JOIN especialidade AS e  ON e.id = m.especialidade_id
    LEFT JOIN convenio       AS cv ON cv.id = c.convenio_id;
```

Resposta do servidor: `CREATE VIEW`. A tabela `pessoa` aparece duas vezes, com os apelidos `pp` e `pm`, porque o nome do paciente e o nome do médico vêm de linhas diferentes da mesma tabela. O convênio entra por `LEFT JOIN`, para que as consultas particulares não desapareçam da visão.

### 10.2 Consultas sobre a visão

```sql
SELECT
    consulta,
    data_consulta,
    medico,
    especialidade,
    convenio,
    valor
FROM
    vw_consulta
WHERE
    paciente = 'João Silva'
ORDER BY
    data_consulta;
```

| consulta | data_consulta | medico | especialidade | convenio | valor |
|---|---|---|---|---|---|
| 1 | 2026-08-03 | Paulo Araújo | Cardiologia | Vida Plena | 180.00 |
| 8 | 2026-08-12 | Beatriz Nascimento | Clínica Geral | Amparo Saúde | 150.00 |

```sql
SELECT
    especialidade,
    SUM(valor) AS faturamento
FROM
    vw_consulta
WHERE
    convenio = 'Particular'
GROUP BY
    especialidade
ORDER BY
    faturamento DESC;
```

| especialidade | faturamento |
|---|---|
| Cardiologia | 320.00 |
| Ortopedia | 300.00 |
| Pediatria | 280.00 |
| Clínica Geral | 250.00 |

As consultas sobre a visão não mencionam nenhuma junção, e as colunas têm os nomes dados na definição. Se uma consulta nova for inserida em `consulta`, ela aparece na visão na próxima vez em que a visão for usada, sem nenhuma alteração na visão. A visão é removida com `DROP VIEW`, e a remoção não afeta as tabelas.

---

## 11. Parte 9. Transações

### 11.1 Várias instruções como uma unidade

O cadastro de um paciente novo exige duas inserções: uma em `pessoa` e outra em `paciente`. Se a primeira for executada e a segunda falhar, o banco fica com uma pessoa que não é paciente nem médico, o que viola a especialização total da regra 3. Uma **transação** é um conjunto de instruções executado como uma unidade: ou todas têm efeito, ou nenhuma tem (ELMASRI e NAVATHE, seção 20.1).

| Instrução | Efeito |
|---|---|
| `BEGIN` | inicia a transação |
| `COMMIT` | confirma todas as alterações feitas desde o `BEGIN` |
| `ROLLBACK` | desfaz todas as alterações feitas desde o `BEGIN` |

Fora de uma transação iniciada com `BEGIN`, o servidor confirma cada instrução assim que ela termina, como aconteceu em todos os roteiros até aqui.

### 11.2 O cadastro confirmado

```sql
BEGIN;

INSERT INTO pessoa (nome, cpf, data_nascimento, logradouro, numero, bairro, cidade)
VALUES ('Helena Prado', '242.242.242-24', '2000-01-15', 'Rua Major Gote', '700', 'Centro', 'Patos de Minas');

INSERT INTO paciente (pessoa_id, data_cadastro, titular_id)
VALUES ((SELECT id FROM pessoa WHERE cpf = '242.242.242-24'), '2026-10-13', NULL);

COMMIT;
```

Respostas do servidor: `BEGIN`, `INSERT 0 1`, `INSERT 0 1` e `COMMIT`. A segunda inserção usa uma subconsulta escalar para obter a chave gerada para Helena Prado, localizada pelo CPF, que é chave candidata. Helena recebe a chave 22.

### 11.3 O cadastro desfeito

Na transação abaixo, a segunda inserção informa um titular que não existe e é recusada.

```sql
BEGIN;

INSERT INTO pessoa (nome, cpf, data_nascimento, logradouro, numero, bairro, cidade)
VALUES ('Otávio Reis', '252.252.252-25', '1999-05-05', 'Rua Rui Barbosa', '12', 'Brasil', 'Patos de Minas');

INSERT INTO paciente (pessoa_id, data_cadastro, titular_id)
VALUES ((SELECT id FROM pessoa WHERE cpf = '252.252.252-25'), '2026-10-13', 99);

ROLLBACK;
```

```
ERROR:  insert or update on table "paciente" violates foreign key constraint "paciente_titular_id_fkey"
DETAIL:  Key (titular_id)=(99) is not present in table "paciente".
```

Depois do erro, o servidor recusa qualquer outra instrução da transação com `current transaction is aborted, commands ignored until end of transaction block`, até que ela seja encerrada. O `ROLLBACK` desfaz também a primeira inserção, que tinha sido aceita.

```sql
SELECT
    COUNT(*) AS otavio
FROM
    pessoa
WHERE
    cpf = '252.252.252-25';
```

| otavio |
|---|
| 0 |

Otávio Reis não ficou cadastrado como pessoa sem ser paciente. Sem a transação, a primeira inserção teria sido confirmada sozinha.

### 11.4 A exclusão em cascata observada dentro de uma transação

A transação também permite observar o efeito de uma instrução e desfazê-lo em seguida. A consulta 14 tem dois exames solicitados.

```sql
BEGIN;

DELETE FROM consulta
WHERE id = 14;

SELECT
    COUNT(*) AS exames_da_14
FROM
    exame_solicitado
WHERE
    consulta_id = 14;

ROLLBACK;
```

| exames_da_14 |
|---|
| 0 |

Dentro da transação, a exclusão da consulta levou junto os dois exames, pelo `ON DELETE CASCADE` da seção 4.7. Depois do `ROLLBACK`, a mesma contagem devolve 2: a consulta e os exames voltaram.

---

## 12. Parte 10. A normalização: a planilha do consultório

### 12.1 O ponto de partida

Antes do banco de dados, o consultório registrava os atendimentos em uma planilha, com uma linha por consulta e todas as informações da consulta na mesma linha. A Parte 2 construiu as tabelas a partir das regras do minimundo. Esta parte faz o caminho por outra via: parte da planilha e chega às mesmas tabelas aplicando as **formas normais**, critérios que dizem quando uma tabela está livre de certos tipos de repetição (ELMASRI e NAVATHE, seção 14.3). Os dois caminhos devem chegar ao mesmo resultado, e chegar é a confirmação de que o projeto está correto.

A planilha é reproduzida como uma tabela, com seis das consultas do roteiro. A tabela não tem chave nem restrições, como uma planilha.

```sql
CREATE TABLE planilha_atendimento (
    consulta      INTEGER,
    data_consulta DATE,
    paciente_cpf  TEXT,
    paciente_nome TEXT,
    telefones     TEXT,
    medico_crm    TEXT,
    medico_nome   TEXT,
    especialidade TEXT,
    convenio      TEXT,
    valor         NUMERIC(10,2),
    exames        TEXT
);

INSERT INTO planilha_atendimento
VALUES
    ( 1, '2026-08-03', '111.111.111-11', 'João Silva',      '34 99999-0001, 34 3821-0001', 'CRM-MG 1001', 'Paulo Araújo',       'Cardiologia',   'Vida Plena',   180.00, 'Eletrocardiograma, Hemograma'),
    ( 3, '2026-08-05', '333.333.333-33', 'José Santos',     '34 99999-0003',               'CRM-MG 1002', 'Beatriz Nascimento', 'Clínica Geral', NULL,           250.00, 'Hemograma'),
    ( 4, '2026-08-06', '444.444.444-44', 'Ana Oliveira',    '34 99999-0004, 34 3821-0004', 'CRM-MG 1003', 'Victor Almeida',     'Ortopedia',     'Vida Plena',   200.00, 'Radiografia da coluna'),
    ( 8, '2026-08-12', '111.111.111-11', 'João Silva',      '34 99999-0001, 34 3821-0001', 'CRM-MG 1002', 'Beatriz Nascimento', 'Clínica Geral', 'Amparo Saúde', 150.00, NULL),
    (14, '2026-08-20', '333.333.333-33', 'José Santos',     '34 99999-0003',               'CRM-MG 1003', 'Victor Almeida',     'Ortopedia',     NULL,           300.00, 'Ressonância do joelho, Hemograma'),
    (18, '2026-08-26', '777.777.777-77', 'Ricardo Almeida', '34 99999-0007',               'CRM-MG 1001', 'Paulo Araújo',       'Cardiologia',   NULL,           320.00, 'Ecocardiograma');
```

```sql
SELECT
    consulta,
    paciente_nome,
    telefones,
    exames
FROM
    planilha_atendimento
ORDER BY
    consulta;
```

| consulta | paciente_nome | telefones | exames |
|---|---|---|---|
| 1 | João Silva | 34 99999-0001, 34 3821-0001 | Eletrocardiograma, Hemograma |
| 3 | José Santos | 34 99999-0003 | Hemograma |
| 4 | Ana Oliveira | 34 99999-0004, 34 3821-0004 | Radiografia da coluna |
| 8 | João Silva | 34 99999-0001, 34 3821-0001 | NULL |
| 14 | José Santos | 34 99999-0003 | Ressonância do joelho, Hemograma |
| 18 | Ricardo Almeida | 34 99999-0007 | Ecocardiograma |

As anomalias do roteiro prático 01 reaparecem. Os telefones de João Silva estão gravados duas vezes, uma em cada consulta dele, e uma troca de número exige alterar as duas linhas: anomalia de modificação. Um paciente cadastrado sem consulta não tem onde ser registrado: anomalia de inserção. Apagar a consulta 18 apaga Ricardo Almeida do cadastro: anomalia de exclusão.

### 12.2 As dependências funcionais

Uma **dependência funcional** X → Y, lida "X determina Y", diz que todas as linhas com o mesmo valor de X têm o mesmo valor de Y (ELMASRI e NAVATHE, seção 14.2). A dependência é uma afirmação sobre as regras do minimundo, e não sobre os dados de um dia. Os dados podem apenas confirmá-la, como na consulta abaixo.

```sql
SELECT
    medico_crm,
    COUNT(*)                      AS linhas,
    COUNT(DISTINCT medico_nome)   AS nomes,
    COUNT(DISTINCT especialidade) AS especialidades
FROM
    planilha_atendimento
GROUP BY
    medico_crm
ORDER BY
    medico_crm;
```

| medico_crm | linhas | nomes | especialidades |
|---|---|---|---|
| CRM-MG 1001 | 2 | 1 | 1 |
| CRM-MG 1002 | 2 | 1 | 1 |
| CRM-MG 1003 | 2 | 1 | 1 |

Cada CRM aparece em duas linhas, sempre com o mesmo nome e a mesma especialidade: os dados confirmam `medico_crm → medico_nome, especialidade`, que vem da regra 5. As dependências da planilha, todas tiradas das regras, são estas.

| Determinante | Determina | Regra |
|---|---|---|
| `consulta` | `data_consulta`, `paciente_cpf`, `medico_crm`, `convenio`, `valor` | 7 |
| `paciente_cpf` | `paciente_nome`, `telefones` | 1 e 2 |
| `medico_crm` | `medico_nome`, `especialidade` | 5 |
| `consulta`, número do exame | `exame` | 8 |

### 12.3 Primeira forma normal

Uma tabela está na **primeira forma normal**, 1FN, quando todo atributo tem valor atômico: cada célula guarda um único valor, e não uma lista (ELMASRI e NAVATHE, seção 14.3.4). A planilha viola a 1FN em duas colunas: `telefones` e `exames` guardam listas separadas por vírgula. Com listas, a pergunta "quais pacientes fizeram hemograma?" depende de procurar um pedaço de texto, e um erro de digitação na vírgula passa despercebido.

A correção leva cada lista para uma tabela própria, com uma linha por valor. Os telefones vão para uma tabela com o CPF e o número. Os exames vão para uma tabela com a consulta, o número do exame e o nome do exame. É o mesmo destino dado ao atributo multivalorado na seção 4.3: o atributo multivalorado do modelo conceitual e a violação da 1FN são o mesmo problema visto de dois lados.

### 12.4 Segunda forma normal

Uma tabela está na **segunda forma normal**, 2FN, quando está na 1FN e nenhum atributo que não faz parte de uma chave depende de apenas uma parte de uma chave candidata (ELMASRI e NAVATHE, seção 14.3.5). A definição só tem efeito quando a chave tem mais de uma coluna.

Uma forma comum de chegar à 1FN é repetir a linha da consulta para cada exame, com a chave `(consulta, numero_exame)`. Nessa tabela, `exame` depende da chave inteira, mas `data_consulta`, `paciente_cpf`, `medico_crm`, `convenio` e `valor` dependem só de `consulta`, uma parte da chave. São **dependências parciais**, e cada uma repete a data, o paciente e o médico em todos os exames da mesma consulta. A consulta 8, sem exames, nem teria onde ser gravada.

A correção separa o que depende só de `consulta` em uma tabela com a chave `consulta`, e deixa na tabela dos exames apenas o que depende da chave inteira. O resultado são as tabelas `consulta` e `exame_solicitado` da Parte 2, esta com a chave `(consulta_id, numero)`.

### 12.5 Terceira forma normal

Uma tabela está na **terceira forma normal**, 3FN, quando está na 2FN e nenhum atributo que não faz parte de uma chave depende de outro atributo que também não faz parte de uma chave (ELMASRI e NAVATHE, seção 14.3.6). A tabela de consultas obtida na seção 12.4 ainda guarda `paciente_nome`, que depende de `paciente_cpf`, e `medico_nome` e `especialidade`, que dependem de `medico_crm`. A chave determina o CPF, e o CPF determina o nome: `consulta → paciente_cpf → paciente_nome`. É uma **dependência transitiva**, e ela repete o nome do paciente em todas as consultas dele.

A correção leva cada determinante para a sua tabela: o CPF e o nome para `paciente`, o CRM, o nome e a especialidade para `medico`. A consulta guarda só a referência ao paciente e ao médico.

### 12.6 O resultado

| Forma normal | Problema na planilha | Tabelas resultantes |
|---|---|---|
| 1FN | listas em `telefones` e `exames` | `telefone`, `exame_solicitado` |
| 2FN | dados da consulta repetidos em cada exame | `consulta` separada de `exame_solicitado` |
| 3FN | nome do paciente e do médico repetidos em cada consulta | `paciente`, `medico` |

As tabelas obtidas são as da Parte 2, com duas diferenças. A Parte 2 usa chaves geradas, `id`, no lugar do CPF e do CRM, que continuam únicos por `UNIQUE`. E a Parte 2 tem também `pessoa`, `especialidade`, `convenio` e `credenciamento`, que vêm de regras que a planilha não registrava: a especialização de pessoa, a lista de especialidades, a lista de convênios e o credenciamento. A normalização confirma o projeto, mas não substitui a modelagem: ela trabalha sobre os atributos que já existem e não descobre o que a planilha não guardava.

---

## 13. O modelo resultante

| Tabela | Chave primária | Chaves estrangeiras | Elemento do diagrama | Linhas |
|---|---|---|---|---|
| `pessoa` | `id` | nenhuma | superclasse PESSOA | 22 |
| `telefone` | `(pessoa_id, numero)` | `pessoa_id` | atributo multivalorado | 22 |
| `especialidade` | `id` | nenhuma | entidade ESPECIALIDADE | 7 |
| `convenio` | `id` | nenhuma | entidade CONVENIO | 4 |
| `paciente` | `pessoa_id` | `pessoa_id`, `titular_id` | subclasse PACIENTE e autorrelacionamento DEPENDE_DE | 17 |
| `medico` | `pessoa_id` | `pessoa_id`, `especialidade_id` | subclasse MEDICO e relacionamento POSSUI | 6 |
| `credenciamento` | `(medico_id, convenio_id)` | as duas | relacionamento N:M CREDENCIADO | 8 |
| `consulta` | `id` | `paciente_id`, `medico_id`, `convenio_id` | entidade CONSULTA e relacionamentos REALIZA, ATENDE e PAGA | 20 |
| `exame_solicitado` | `(consulta_id, numero)` | `consulta_id`, com `ON DELETE CASCADE` | entidade fraca EXAME_SOLICITADO | 8 |

As contagens de `pessoa` e `paciente` incluem Helena Prado, cadastrada na seção 11.2. A tabela `planilha_atendimento`, da Parte 10, reproduz o registro anterior ao banco de dados e não faz parte do modelo.

---

## 14. Erros frequentes e leitura das mensagens

| Mensagem ou sintoma | Causa | Correção |
|---|---|---|
| `relation "pessoa" does not exist` ao criar uma subclasse | Subclasse criada antes da superclasse | Criar as tabelas na ordem da Parte 2 |
| `multiple primary keys for table "telefone" are not allowed` | `PRIMARY KEY` escrito ao lado de duas colunas | Declarar a chave composta ao final, `PRIMARY KEY (pessoa_id, numero)` |
| `duplicate key value violates unique constraint "paciente_pkey"` | A mesma pessoa cadastrada duas vezes como paciente | Conferir se a pessoa já é paciente antes de inserir |
| `insert or update on table "medico" violates foreign key constraint` com `is not present in table "pessoa"` | Médico inserido antes da pessoa | Inserir a pessoa primeiro, de preferência na mesma transação |
| `column reference "nome" is ambiguous` | `pessoa` usada duas vezes, ou `nome` existente em mais de uma tabela, sem apelido | Prefixar com o apelido de cada ocorrência |
| Autojunção sem resultado | Condição invertida, `d.pessoa_id = t.titular_id` | Ligar a chave estrangeira do dependente à chave do titular |
| `aggregate functions are not allowed in WHERE` | Comparação direta com `AVG` no `WHERE` | Usar subconsulta escalar ou `HAVING` |
| `more than one row returned by a subquery used as an expression` | Subconsulta escalar que devolve várias linhas | Usar `IN`, ou corrigir a subconsulta para devolver uma linha |
| `NOT IN` sem nenhuma linha, sem erro | Nulo na lista devolvida pela subconsulta | Usar `NOT EXISTS` |
| `each UNION query must have the same number of columns` | Consultas incompatíveis na operação de conjunto | Igualar o número e a ordem das colunas |
| `current transaction is aborted, commands ignored until end of transaction block` | Instrução enviada depois de um erro dentro da transação | Encerrar com `ROLLBACK` e recomeçar |
| `cannot drop table consulta because other objects depend on it` | A visão `vw_consulta` depende da tabela | Remover a visão antes, pela seção 2.2 |

---

## 15. Script consolidado

Todo o código do roteiro, na ordem de execução. As instruções que o servidor recusa de propósito, nas seções 5.2 e 11.3, e as consultas de demonstração da seção 9.4 ficam fora.

```sql
-- ===============================================================
-- Roteiro pratico 02. Conexao: bd_plano_saude, esquema public
-- ===============================================================
-- Active: 1787177433004@@127.0.0.1@5432@bd_plano_saude@public

-- ---------------------------------------------------------------
-- Recomeco
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- Parte 2. Do modelo as tabelas
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- Parte 3. A carga
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- Parte 4. Consultas com juncao
-- ---------------------------------------------------------------
SELECT
    pe.nome,
    pa.data_cadastro,
    DATE_PART('year', AGE(CURRENT_DATE, pe.data_nascimento)) AS idade
FROM
    paciente AS pa
    INNER JOIN pessoa AS pe ON pe.id = pa.pessoa_id
ORDER BY
    pe.nome
LIMIT 5;

SELECT
    pe.nome,
    m.crm,
    e.nome AS especialidade
FROM
    medico AS m
    INNER JOIN pessoa        AS pe ON pe.id = m.pessoa_id
    INNER JOIN especialidade AS e  ON e.id  = m.especialidade_id
ORDER BY
    pe.nome;

SELECT
    dep.nome AS dependente,
    tit.nome AS titular
FROM
    paciente AS d
    INNER JOIN pessoa   AS dep ON dep.id = d.pessoa_id
    INNER JOIN paciente AS t   ON t.pessoa_id = d.titular_id
    INNER JOIN pessoa   AS tit ON tit.id = t.pessoa_id
ORDER BY
    dep.nome;

SELECT
    pm.nome AS medico,
    cv.nome AS convenio,
    cr.data_inicio
FROM
    credenciamento AS cr
    INNER JOIN pessoa   AS pm ON pm.id = cr.medico_id
    INNER JOIN convenio AS cv ON cv.id = cr.convenio_id
ORDER BY
    pm.nome,
    cv.nome;

SELECT
    c.id AS consulta,
    c.data_consulta,
    es.numero,
    es.exame
FROM
    consulta AS c
    INNER JOIN exame_solicitado AS es ON es.consulta_id = c.id
ORDER BY
    c.id,
    es.numero;

SELECT
    pe.nome,
    COUNT(t.numero) AS telefones
FROM
    pessoa AS pe
    LEFT JOIN telefone AS t ON t.pessoa_id = pe.id
GROUP BY
    pe.id,
    pe.nome
HAVING
    COUNT(t.numero) <> 1
ORDER BY
    telefones DESC,
    pe.nome;

-- ---------------------------------------------------------------
-- Parte 5. Agregacao sobre tabelas relacionadas
-- ---------------------------------------------------------------
SELECT
    COALESCE(cv.nome, 'Particular') AS convenio,
    COUNT(c.id)                     AS consultas,
    COALESCE(SUM(c.valor), 0)       AS faturamento
FROM
    consulta AS c
    FULL JOIN convenio AS cv ON cv.id = c.convenio_id
GROUP BY
    cv.nome
ORDER BY
    faturamento DESC;

SELECT
    e.nome                 AS especialidade,
    COUNT(c.id)            AS consultas,
    ROUND(AVG(c.valor), 2) AS valor_medio
FROM
    especialidade AS e
    INNER JOIN medico   AS m ON m.especialidade_id = e.id
    INNER JOIN consulta AS c ON c.medico_id = m.pessoa_id
GROUP BY
    e.nome
HAVING
    COUNT(c.id) >= 3
ORDER BY
    consultas DESC;

-- ---------------------------------------------------------------
-- Parte 6. Subconsultas
-- ---------------------------------------------------------------
SELECT
    c.id,
    c.data_consulta,
    c.valor
FROM
    consulta AS c
WHERE
    c.valor > (SELECT AVG(valor) FROM consulta)
ORDER BY
    c.valor DESC,
    c.id;

SELECT
    pe.nome
FROM
    pessoa AS pe
WHERE
    pe.id IN (SELECT paciente_id
              FROM consulta
              WHERE convenio_id IS NULL)
ORDER BY
    pe.nome;

SELECT
    pe.nome
FROM
    paciente AS pa
    INNER JOIN pessoa AS pe ON pe.id = pa.pessoa_id
WHERE
    NOT EXISTS (SELECT 1
                FROM consulta AS c
                WHERE c.paciente_id = pa.pessoa_id)
ORDER BY
    pe.nome;

SELECT
    c.id,
    c.medico_id,
    c.convenio_id
FROM
    consulta AS c
WHERE
    c.convenio_id IS NOT NULL
    AND NOT EXISTS (SELECT 1
                    FROM credenciamento AS cr
                    WHERE cr.medico_id   = c.medico_id
                      AND cr.convenio_id = c.convenio_id);

SELECT
    pm.nome AS medico,
    c.id    AS consulta,
    c.valor
FROM
    consulta AS c
    INNER JOIN pessoa AS pm ON pm.id = c.medico_id
WHERE
    c.valor = (SELECT MAX(c2.valor)
               FROM consulta AS c2
               WHERE c2.medico_id = c.medico_id)
ORDER BY
    pm.nome,
    c.id;

SELECT
    pe.nome AS titular,
    (SELECT COUNT(*)
     FROM paciente AS d
     WHERE d.titular_id = pa.pessoa_id) AS dependentes
FROM
    paciente AS pa
    INNER JOIN pessoa AS pe ON pe.id = pa.pessoa_id
WHERE
    pa.titular_id IS NULL
ORDER BY
    dependentes DESC,
    pa.pessoa_id
LIMIT 5;

SELECT
    nome
FROM
    convenio AS cv
WHERE
    NOT EXISTS (SELECT 1
                FROM consulta AS c
                WHERE c.convenio_id = cv.id);

-- ---------------------------------------------------------------
-- Parte 7. Operacoes de conjunto
-- ---------------------------------------------------------------
SELECT
    pe.nome
FROM
    pessoa AS pe
WHERE
    pe.id IN (SELECT pessoa_id FROM paciente
              INTERSECT
              SELECT pessoa_id FROM medico);

SELECT pessoa_id FROM paciente
EXCEPT
SELECT paciente_id FROM consulta
ORDER BY 1;

-- ---------------------------------------------------------------
-- Parte 8. Visoes
-- ---------------------------------------------------------------
CREATE VIEW vw_consulta AS
SELECT
    c.id                            AS consulta,
    c.data_consulta,
    pp.nome                         AS paciente,
    pm.nome                         AS medico,
    e.nome                          AS especialidade,
    COALESCE(cv.nome, 'Particular') AS convenio,
    c.valor
FROM
    consulta AS c
    INNER JOIN pessoa        AS pp ON pp.id = c.paciente_id
    INNER JOIN medico        AS m  ON m.pessoa_id = c.medico_id
    INNER JOIN pessoa        AS pm ON pm.id = m.pessoa_id
    INNER JOIN especialidade AS e  ON e.id = m.especialidade_id
    LEFT JOIN convenio       AS cv ON cv.id = c.convenio_id;

SELECT
    consulta,
    data_consulta,
    medico,
    especialidade,
    convenio,
    valor
FROM
    vw_consulta
WHERE
    paciente = 'João Silva'
ORDER BY
    data_consulta;

SELECT
    especialidade,
    SUM(valor) AS faturamento
FROM
    vw_consulta
WHERE
    convenio = 'Particular'
GROUP BY
    especialidade
ORDER BY
    faturamento DESC;

-- ---------------------------------------------------------------
-- Parte 9. Transacoes
-- ---------------------------------------------------------------
BEGIN;

INSERT INTO pessoa (nome, cpf, data_nascimento, logradouro, numero, bairro, cidade)
VALUES ('Helena Prado', '242.242.242-24', '2000-01-15', 'Rua Major Gote', '700', 'Centro', 'Patos de Minas');

INSERT INTO paciente (pessoa_id, data_cadastro, titular_id)
VALUES ((SELECT id FROM pessoa WHERE cpf = '242.242.242-24'), '2026-10-13', NULL);

COMMIT;

BEGIN;

DELETE FROM consulta
WHERE id = 14;

SELECT
    COUNT(*) AS exames_da_14
FROM
    exame_solicitado
WHERE
    consulta_id = 14;

ROLLBACK;

-- ---------------------------------------------------------------
-- Parte 10. A normalizacao: a planilha do consultorio
-- ---------------------------------------------------------------
CREATE TABLE planilha_atendimento (
    consulta      INTEGER,
    data_consulta DATE,
    paciente_cpf  TEXT,
    paciente_nome TEXT,
    telefones     TEXT,
    medico_crm    TEXT,
    medico_nome   TEXT,
    especialidade TEXT,
    convenio      TEXT,
    valor         NUMERIC(10,2),
    exames        TEXT
);

INSERT INTO planilha_atendimento
VALUES
    ( 1, '2026-08-03', '111.111.111-11', 'João Silva',      '34 99999-0001, 34 3821-0001', 'CRM-MG 1001', 'Paulo Araújo',       'Cardiologia',   'Vida Plena',   180.00, 'Eletrocardiograma, Hemograma'),
    ( 3, '2026-08-05', '333.333.333-33', 'José Santos',     '34 99999-0003',               'CRM-MG 1002', 'Beatriz Nascimento', 'Clínica Geral', NULL,           250.00, 'Hemograma'),
    ( 4, '2026-08-06', '444.444.444-44', 'Ana Oliveira',    '34 99999-0004, 34 3821-0004', 'CRM-MG 1003', 'Victor Almeida',     'Ortopedia',     'Vida Plena',   200.00, 'Radiografia da coluna'),
    ( 8, '2026-08-12', '111.111.111-11', 'João Silva',      '34 99999-0001, 34 3821-0001', 'CRM-MG 1002', 'Beatriz Nascimento', 'Clínica Geral', 'Amparo Saúde', 150.00, NULL),
    (14, '2026-08-20', '333.333.333-33', 'José Santos',     '34 99999-0003',               'CRM-MG 1003', 'Victor Almeida',     'Ortopedia',     NULL,           300.00, 'Ressonância do joelho, Hemograma'),
    (18, '2026-08-26', '777.777.777-77', 'Ricardo Almeida', '34 99999-0007',               'CRM-MG 1001', 'Paulo Araújo',       'Cardiologia',   NULL,           320.00, 'Ecocardiograma');

SELECT
    consulta,
    paciente_nome,
    telefones,
    exames
FROM
    planilha_atendimento
ORDER BY
    consulta;

SELECT
    medico_crm,
    COUNT(*)                      AS linhas,
    COUNT(DISTINCT medico_nome)   AS nomes,
    COUNT(DISTINCT especialidade) AS especialidades
FROM
    planilha_atendimento
GROUP BY
    medico_crm
ORDER BY
    medico_crm;
```

---

## 16. Exercícios

Os enunciados devem ser resolvidos sem consultar a seção 17, na ordem em que aparecem, sobre o estado em que as tabelas ficam ao final do script da seção 15. Cada resposta deve ser escrita por inteiro em `roteiro02.sql`, precedida de um comentário com o seu número.

**Modelo**

1. O consultório passou a registrar os planos de cada convênio, como Básico e Executivo, e cada paciente passa a ter um plano. Indicar os novos tipos de entidade e de relacionamento, com a cardinalidade e a participação de cada lado, e as tabelas e colunas que o mapeamento produziria.
2. Explicar por que `exame_solicitado` é uma entidade fraca e `credenciamento` não é uma entidade, mas um relacionamento, embora as duas tabelas tenham chave primária composta.
3. A especialização de PESSOA é sobreposta e total. Indicar qual consulta do roteiro comprova cada uma das duas restrições sobre os dados.

**Junção e agregação**

4. Listar os médicos com a especialidade e a quantidade de convênios a que cada um é credenciado, incluindo os que não têm credenciamento, ordenados pela quantidade em ordem decrescente e pela chave do médico.
5. Listar os pacientes que moram em Lagoa Formosa, com o nome e a idade, da maior idade para a menor.

**Subconsultas e conjuntos**

6. Listar os médicos credenciados ao convênio Amparo Saúde que nunca atenderam uma consulta por esse convênio.
7. Listar as consultas cujo valor é maior que a média das consultas da mesma especialidade, com o número da consulta, a especialidade e o valor, ordenadas pelo número.
8. Listar, com uma operação de conjunto, as especialidades que não têm nenhum médico.

**Visões e transações**

9. Criar a visão `vw_dependente`, com o nome do dependente e o nome do titular, e consultá-la, ordenada pelo nome do dependente.
10. Registrar, em uma única transação, uma consulta de Felipe Ribeiro com Victor Almeida, pelo convênio Bem Viver, em 13/10/2026, no valor de R$ 200,00, com dois exames solicitados: radiografia do ombro e hemograma. Explicar por que a transação é necessária e por que a seção 8.5 deve ser executada de novo depois do registro.

**Normalização**

11. A recepção propôs acrescentar à tabela `consulta` a coluna `especialidade`, para não precisar de junção ao listar as consultas. Indicar a dependência que essa coluna criaria, qual forma normal seria violada e qual anomalia de modificação ela provocaria.
12. Na planilha da Parte 10, a coluna `convenio` guarda o nome do convênio. Indicar por que essa coluna não viola a 3FN na planilha, e o que mudaria se a planilha guardasse também o telefone de contato de cada convênio.

---

## 17. Gabarito

### Exercício 1

Surge o tipo de entidade PLANO, com nome, e dois relacionamentos. OFERECE liga CONVENIO a PLANO, 1:N: um convênio oferece vários planos, e cada plano é de um convênio. A participação de PLANO é total, porque não há plano sem convênio, e a de CONVENIO é parcial, porque um convênio recém-credenciado pode ainda não ter planos cadastrados. ASSINA liga PLANO a PACIENTE, 1:N: um plano tem vários pacientes, e cada paciente tem um plano. A participação de PACIENTE é total, pelo enunciado, e a de PLANO é parcial. O mapeamento produz a tabela `plano`, com `id`, `nome` e `convenio_id INTEGER NOT NULL REFERENCES convenio (id)`, e a coluna `plano_id INTEGER NOT NULL REFERENCES plano (id)` em `paciente`. Se os dependentes herdarem o plano do titular, a participação de PACIENTE passa a ser parcial, e `plano_id` aceita nulo nos dependentes.

### Exercício 2

O exame solicitado não tem atributo-chave próprio: o número 1 se repete entre consultas, e o exame só é identificado pelo par formado pela consulta e pelo número. Ele depende da consulta para existir e para ser identificado. O credenciamento não tem existência própria nem atributos que o identifiquem: ele é a associação entre um médico e um convênio, que existem independentemente dele, e o seu único atributo, a data de início, descreve o par. A chave composta tem origens diferentes nos dois casos. Em `exame_solicitado`, reúne a chave da proprietária e a chave parcial. Em `credenciamento`, reúne as chaves das duas entidades associadas.

### Exercício 3

A sobreposição é comprovada pelo `INTERSECT` da seção 9.2, que devolve a pessoa 17, presente nas duas subclasses. A completude é comprovada pelo `UNION` da seção 9.4, que devolve o mesmo número de linhas de `pessoa`: 21 na seção 9.4 e 22 depois do cadastro de Helena Prado. Nenhuma pessoa ficou fora das duas subclasses.

### Exercício 4

```sql
SELECT
    pm.nome               AS medico,
    e.nome                AS especialidade,
    COUNT(cr.convenio_id) AS convenios
FROM
    medico AS m
    INNER JOIN pessoa        AS pm ON pm.id = m.pessoa_id
    INNER JOIN especialidade AS e  ON e.id = m.especialidade_id
    LEFT JOIN credenciamento AS cr ON cr.medico_id = m.pessoa_id
GROUP BY
    m.pessoa_id,
    pm.nome,
    e.nome
ORDER BY
    convenios DESC,
    m.pessoa_id;
```

| medico | especialidade | convenios |
|---|---|---|
| Paulo Araújo | Cardiologia | 2 |
| Beatriz Nascimento | Clínica Geral | 2 |
| Victor Almeida | Ortopedia | 2 |
| Camila Rodrigues | Pediatria | 1 |
| Thiago Santos | Dermatologia | 1 |
| Daniela Alves | Oftalmologia | 0 |

### Exercício 5

```sql
SELECT
    pe.nome,
    DATE_PART('year', AGE(CURRENT_DATE, pe.data_nascimento)) AS idade
FROM
    paciente AS pa
    INNER JOIN pessoa AS pe ON pe.id = pa.pessoa_id
WHERE
    pe.cidade = 'Lagoa Formosa'
ORDER BY
    idade DESC;
```

| nome | idade |
|---|---|
| Felipe Ribeiro | 44 |
| Laura Mendes | 33 |

Idades calculadas em 13/10/2026.

### Exercício 6

```sql
SELECT
    pm.nome AS medico
FROM
    credenciamento AS cr
    INNER JOIN pessoa   AS pm ON pm.id = cr.medico_id
    INNER JOIN convenio AS cv ON cv.id = cr.convenio_id
WHERE
    cv.nome = 'Amparo Saúde'
    AND NOT EXISTS (SELECT 1
                    FROM consulta AS c
                    WHERE c.medico_id   = cr.medico_id
                      AND c.convenio_id = cr.convenio_id);
```

| medico |
|---|
| Thiago Santos |

Beatriz Nascimento também é credenciada ao Amparo Saúde, mas atendeu quatro consultas por ele.

### Exercício 7

```sql
SELECT
    c.id,
    e.nome AS especialidade,
    c.valor
FROM
    consulta AS c
    INNER JOIN medico        AS m ON m.pessoa_id = c.medico_id
    INNER JOIN especialidade AS e ON e.id = m.especialidade_id
WHERE
    c.valor > (SELECT AVG(c2.valor)
               FROM consulta AS c2
                   INNER JOIN medico AS m2 ON m2.pessoa_id = c2.medico_id
               WHERE m2.especialidade_id = m.especialidade_id)
ORDER BY
    c.id;
```

| id | especialidade | valor |
|---|---|---|
| 3 | Clínica Geral | 250.00 |
| 9 | Pediatria | 280.00 |
| 14 | Ortopedia | 300.00 |
| 18 | Cardiologia | 320.00 |

A subconsulta é correlacionada pela especialidade, `m.especialidade_id`, e calcula, para cada consulta da consulta externa, a média das consultas da mesma especialidade. As quatro consultas do resultado são particulares, mais caras que as consultas por convênio da mesma especialidade.

### Exercício 8

```sql
SELECT nome FROM especialidade
EXCEPT
SELECT e.nome
FROM especialidade AS e
    INNER JOIN medico AS m ON m.especialidade_id = e.id;
```

| nome |
|---|
| Neurologia |

### Exercício 9

```sql
CREATE VIEW vw_dependente AS
SELECT
    dep.nome AS dependente,
    tit.nome AS titular
FROM
    paciente AS d
    INNER JOIN pessoa AS dep ON dep.id = d.pessoa_id
    INNER JOIN pessoa AS tit ON tit.id = d.titular_id;

SELECT
    dependente,
    titular
FROM
    vw_dependente
ORDER BY
    dependente;
```

| dependente | titular |
|---|---|
| Laura Mendes | Felipe Ribeiro |
| Lucas Ferreira | João Silva |
| Mariana Gomes | José Santos |

A visão liga o dependente diretamente à pessoa do titular, porque `titular_id` já é a chave da pessoa. A passagem pela segunda ocorrência de `paciente`, feita na seção 6.3, não é necessária.

### Exercício 10

```sql
BEGIN;

INSERT INTO consulta (paciente_id, medico_id, convenio_id, data_consulta, valor)
VALUES (13, 18, 2, '2026-10-13', 200.00);

INSERT INTO exame_solicitado (consulta_id, numero, exame)
VALUES
    ((SELECT MAX(id) FROM consulta), 1, 'Radiografia do ombro'),
    ((SELECT MAX(id) FROM consulta), 2, 'Hemograma');

COMMIT;
```

Respostas do servidor: `BEGIN`, `INSERT 0 1`, `INSERT 0 2` e `COMMIT`. A consulta recebe o código 21. A transação garante que a consulta e os exames sejam registrados juntos: se a inserção dos exames falhasse, a consulta não ficaria registrada sem os exames que o médico pediu. A subconsulta `SELECT MAX(id) FROM consulta` obtém o código da consulta recém-inserida, o maior da tabela, porque a transação é a única em execução. A seção 8.5 deve ser executada de novo porque nenhuma restrição declarada confere o credenciamento: a nova consulta só respeita a regra 6 porque Victor Almeida é credenciado ao Bem Viver, e a consulta da seção 8.5 é a forma de confirmar isso.


### Exercício 11

A coluna criaria a dependência `medico_id → especialidade` dentro de `consulta`: todas as consultas do mesmo médico teriam a mesma especialidade. Como `medico_id` não é chave de `consulta`, a especialidade dependeria da chave por meio do médico, `id → medico_id → especialidade`, uma dependência transitiva que viola a 3FN. Se um médico mudasse de especialidade no cadastro, todas as consultas dele precisariam ser alteradas, e um `UPDATE` que atingisse só parte delas deixaria o mesmo médico com duas especialidades: a anomalia de modificação do tomate, no roteiro prático 01. A listagem sem junção já existe, sem a redundância, na visão `vw_consulta` da Parte 8.

### Exercício 12

Na planilha, `convenio` é um atributo da consulta, determinado pela chave `consulta`, e nenhum outro atributo depende dele: a coluna não cria dependência transitiva. Se a planilha guardasse também o telefone do convênio, surgiria `convenio → telefone_convenio`, e o telefone dependeria da chave por meio do convênio, uma dependência transitiva. A 3FN exigiria uma tabela de convênios, com o nome e o telefone, referenciada pela consulta, que é a tabela `convenio` da Parte 2.

---

## 18. Referências

ELMASRI, R. NAVATHE, S. B. *Sistemas de Banco de Dados*. 7. ed. São Paulo: Pearson, 2018. Seções 3.3 (tipos de entidade, atributos e chaves), 3.4 (relacionamentos, papéis e restrições estruturais), 3.5 (tipos de entidade fraca), 3.9 (relacionamentos de grau maior que dois), 4.1 a 4.3 (subclasses, especialização, generalização e suas restrições), 6.2 (restrições em SQL), 6.3.4 (operações de conjunto), 7.1 (consultas complexas, subconsultas, `EXISTS` e junções), 7.3 (visões), 9.1 e 9.2 (mapeamento do modelo para o relacional), 14.1 a 14.3 (diretrizes de projeto, dependências funcionais e formas normais) e 20.1 (transações).
