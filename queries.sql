-- Temos linhas duplicadas em todas as tabelas, criando tabelas de elementos únicos:
CREATE TABLE disposition_corrigido AS (SELECT DISTINCT *
										FROM disposition
										ORDER BY disp_id);

CREATE TABLE transactions_corrigido AS (SELECT DISTINCT *
										FROM transactions
										ORDER BY trans_id);
										
CREATE TABLE creditcard_corrigido AS (SELECT DISTINCT *
										FROM creditcard
										ORDER BY card_id);

CREATE TABLE account_corrigido AS (SELECT DISTINCT *
										FROM account
										ORDER BY account_id);
										
CREATE TABLE demograph_corrigido AS (SELECT DISTINCT *
									FROM demograph
									ORDER BY "A1");

CREATE TABLE loan_corrigido AS (SELECT DISTINCT *
							   FROM loan
							   ORDER BY loan_id);


CREATE TABLE client_corrigido AS (SELECT DISTINCT *
								  FROM client
								  ORDER BY client_id);
								  
CREATE TABLE permanentorder_corrigido AS (SELECT DISTINCT *
									FROM permanentorder
									ORDER BY order_id);

-- Removendo as antigas:
DROP TABLE account, client, creditcard, demograph, disposition, loan, permanentorder, transactions

---------------------------------------------------------------------------------------------------

--O banco tem como plano diretivo aumentar a adesão de seus clientes aos cartões Gold, para isso, irá realizar uma campanha focada no grupo de clientes onde isso possa ser mais interessante.
-- Através dos gastos com cartão de crédito, o banco irá avaliar a região onde estão os mais "gastadores" das categorias Junior e Classic para focar sua propaganda de milhas para as Bahamas.

-- As tabelas utilizadas serão:
-- coluna "operation" , tabela "transactions" -> queremos a soma de transações do tipo "credit card withdraw" por account_id
-- coluna "type", tabela "creditcard" -> queremos agrupar por tipos de cartões
-- coluna "region"/A3, tabela "demograph" -> queremos agrupar por regiões
-- necessitaremos a tabela "account", que conecta tabelas "demograph" e "transactions"
-- necessitaremos a tabela "disposition", que conecta tabelas "account" e "credit card"
-- necessitaremos a tabela "client" que conecta "district_id" com 

--A tabela final ficaria assim: | regiao | tipo de cartao | SUM(credit card withdraw)


--1. Quantos clientes temos cadastrados no banco e quantos cartões emitidos?
SELECT COUNT(client_id)
FROM client_corrigido;
-- Temos cadastrados 5369 clientes.


--2. Quantos cartões emitidos?
SELECT COUNT(card_id)
FROM creditcard_corrigido;
--892 cartões no total.


--3. Quantos cartões de cada tipo já foram emitidos?
SELECT COUNT(creditcard_corrigido.card_id), creditcard_corrigido.type
FROM creditcard_corrigido
GROUP BY creditcard_corrigido.type;
--Portanto a maioria dos cartões fornecidos são do tipo "Classic". Temos oportunidade de aumentar o serviço "Gold".


--4. Agora avaliaremos quantos cartões e de qual tipo cada cliente tem.
SELECT disposition_corrigido.client_id
		,creditcard_corrigido.type
		,COUNT(creditcard_corrigido.card_id) AS number_cards
FROM creditcard_corrigido
RIGHT JOIN disposition_corrigido
ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
ORDER BY disposition_corrigido.client_id;
-- Essa é a tabela completa que relaciona o cliente com o tipo e número de cartões. Nem todos os clientes possuem cartões.

SELECT MAX(number_cards)
FROM (SELECT disposition_corrigido.client_id
		,creditcard_corrigido.type
		,COUNT(creditcard_corrigido.card_id) AS number_cards
		FROM creditcard_corrigido
		RIGHT JOIN disposition_corrigido
		ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
		GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
		ORDER BY disposition_corrigido.client_id) as subquery0;
-- Máximo = 1. Nenhum cliente tem mais de um tipo de cartão, quando tem. Isso também já era esperado.

SELECT MIN(number_cards)
FROM (SELECT disposition_corrigido.client_id
		,creditcard_corrigido.type
		,COUNT(creditcard_corrigido.card_id) AS number_cards
		FROM creditcard_corrigido
		RIGHT JOIN disposition_corrigido
		ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
		GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
		ORDER BY disposition_corrigido.client_id) as subquery0;
-- Mínimo = 0. Nem todos os clientes possuem cartões.

SELECT *
FROM (SELECT disposition_corrigido.client_id
		,creditcard_corrigido.type
		,COUNT(creditcard_corrigido.card_id) AS number_cards
		FROM creditcard_corrigido
		RIGHT JOIN disposition_corrigido
		ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
		GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
		ORDER BY disposition_corrigido.client_id) as subquery0
WHERE type IN ('gold','classic','junior');

SELECT 5369-892;
-- Dos 5369 clientes, 892 possuem 1 cartão e o restante (4477 clientes) não possuem cartão. Portanto há oportunidade aí.


--5. Dos clientes que não possuem cartão, em quais distritos e regiões da Rep Tcheca estão?
-- Filtrando por WHERE number_cards = 0:
SELECT *
FROM (SELECT disposition_corrigido.client_id
		,creditcard_corrigido.type
		,COUNT(creditcard_corrigido.card_id) AS number_cards
		FROM creditcard_corrigido
		RIGHT JOIN disposition_corrigido
		ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
		GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
		ORDER BY disposition_corrigido.client_id) AS clients_cards
WHERE number_cards = 0;

-- Criando a tabela CLIENTS_NO_CARDS_INFO:
SELECT client_corrigido.client_id, clients_no_cards.type, clients_no_cards.number_cards, client_corrigido.birth_number, client_corrigido.sex, client_corrigido.district_id
FROM (SELECT *
		FROM (SELECT disposition_corrigido.client_id
					,creditcard_corrigido.type
					,COUNT(creditcard_corrigido.card_id) AS number_cards
					FROM creditcard_corrigido
						RIGHT JOIN disposition_corrigido
						ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
						GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
						ORDER BY disposition_corrigido.client_id) as clients_cards
		WHERE number_cards = 0) AS clients_no_cards
LEFT JOIN client_corrigido
ON clients_no_cards.client_id = client_corrigido.client_id;

--Selecionando somente o sexo e a contagem de gênero a partir da CLIENTS_NO_CARDS_INFO:
SELECT sex, count(sex)
FROM
	(
	SELECT *
	FROM (SELECT *
			FROM (SELECT disposition_corrigido.client_id
						,creditcard_corrigido.type
						,COUNT(creditcard_corrigido.card_id) AS number_cards
						FROM creditcard_corrigido
							RIGHT JOIN disposition_corrigido
							ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
							GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
							ORDER BY disposition_corrigido.client_id) as clients_cards
			WHERE number_cards = 0) AS clients_no_cards
	LEFT JOIN client_corrigido
	ON clients_no_cards.client_id = client_corrigido.client_id
	) AS clients_no_cards_info
GROUP BY sex
-- Não há diferença entre gênero quando se trata de não ter cartão

-- Há diferença por distrito? Vamos descobrir os top 10 distritos onde mais há clientes sem-cartão.
SELECT district_id, count(district_id)
FROM
	(
	SELECT *
	FROM (SELECT *
			FROM (SELECT disposition_corrigido.client_id
						,creditcard_corrigido.type
						,COUNT(creditcard_corrigido.card_id) AS number_cards
						FROM creditcard_corrigido
							RIGHT JOIN disposition_corrigido
							ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
							GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
							ORDER BY disposition_corrigido.client_id) as clients_cards
			WHERE number_cards = 0) AS clients_no_cards
	LEFT JOIN client_corrigido
	ON clients_no_cards.client_id = client_corrigido.client_id
	) AS clients_no_cards_info
GROUP BY district_id
ORDER BY COUNT(district_id) DESC
LIMIT 10;
-- 533 clientes sem-cartão no district_id = 1. No total do top 10, temos 1411 clientes sem cartão, o que representa 30% de todos os clientes sem-cartão do banco.

--Agora teremos que joinar a tabela CLIENTS_NO_CARDS_INFO com a tabela DEMOGRAPH.
--Essa é a tabela CLIENTS_NO_CARDS_INFO_DEMO
SELECT clients_no_cards_info.client_id, clients_no_cards_info.type, clients_no_cards_info.number_cards, clients_no_cards_info.birth_number, clients_no_cards_info.sex, demograph_corrigido.*
FROM(
	SELECT client_corrigido.client_id, clients_no_cards.type, clients_no_cards.number_cards, client_corrigido.birth_number, client_corrigido.sex, client_corrigido.district_id
	FROM (SELECT *
			FROM (SELECT disposition_corrigido.client_id
						,creditcard_corrigido.type
						,COUNT(creditcard_corrigido.card_id) AS number_cards
						FROM creditcard_corrigido
							RIGHT JOIN disposition_corrigido
							ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
							GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
							ORDER BY disposition_corrigido.client_id) as clients_cards
			WHERE number_cards = 0) AS clients_no_cards
	LEFT JOIN client_corrigido
	ON clients_no_cards.client_id = client_corrigido.client_id
	) AS clients_no_cards_info
LEFT JOIN demograph_corrigido
ON demograph_corrigido."A1" = clients_no_cards_info.district_id;

--Vamos verificar a qual região pertencia o distrito 1.
SELECT count(client_id),  "A1", "A3"
FROM(
	SELECT clients_no_cards_info.client_id, clients_no_cards_info.type, clients_no_cards_info.number_cards, clients_no_cards_info.birth_number, clients_no_cards_info.sex, demograph_corrigido.*
	FROM(
		SELECT client_corrigido.client_id, clients_no_cards.type, clients_no_cards.number_cards, client_corrigido.birth_number, client_corrigido.sex, client_corrigido.district_id
		FROM (SELECT *
				FROM (SELECT disposition_corrigido.client_id
							,creditcard_corrigido.type
							,COUNT(creditcard_corrigido.card_id) AS number_cards
							FROM creditcard_corrigido
								RIGHT JOIN disposition_corrigido
								ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
								GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
								ORDER BY disposition_corrigido.client_id) as clients_cards
				WHERE number_cards = 0) AS clients_no_cards
		LEFT JOIN client_corrigido
		ON clients_no_cards.client_id = client_corrigido.client_id
		) AS clients_no_cards_info
	LEFT JOIN demograph_corrigido
	ON demograph_corrigido."A1" = clients_no_cards_info.district_id
	) AS clients_no_cards_info_demo
GROUP BY  "A1", "A3"
ORDER BY COUNT(client_id) DESC;
-- O distrito 1 comentado anteriormente faz parte da região de Praga. Portanto há 533 clientes em um distrito sem cartão.

--Vamos verificar qual região da Rep. Tcheca há mais pessoas sem-cartão.
SELECT count(client_id),  "A1", "A3"
FROM(
	SELECT clients_no_cards_info.client_id, clients_no_cards_info.type, clients_no_cards_info.number_cards, clients_no_cards_info.birth_number, clients_no_cards_info.sex, demograph_corrigido.*
	FROM(
		SELECT client_corrigido.client_id, clients_no_cards.type, clients_no_cards.number_cards, client_corrigido.birth_number, client_corrigido.sex, client_corrigido.district_id
		FROM (SELECT *
				FROM (SELECT disposition_corrigido.client_id
							,creditcard_corrigido.type
							,COUNT(creditcard_corrigido.card_id) AS number_cards
							FROM creditcard_corrigido
								RIGHT JOIN disposition_corrigido
								ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
								GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
								ORDER BY disposition_corrigido.client_id) as clients_cards
				WHERE number_cards = 0) AS clients_no_cards
		LEFT JOIN client_corrigido
		ON clients_no_cards.client_id = client_corrigido.client_id
		) AS clients_no_cards_info
	LEFT JOIN demograph_corrigido
	ON demograph_corrigido."A1" = clients_no_cards_info.district_id
	) AS clients_no_cards_info_demo
GROUP BY  "A1", "A3"
ORDER BY COUNT(client_id) DESC;
-- A macro região da South Moravia é a região com mais sem-cartão do país. Porém possivelmente estão dispersos.


--6. Agora pensando em expandir os clientes nas categorias oferecidas de cartões: de Junior para Classic e de Classic para Gold.

--6.1. Onde estão os clientes Junior e Classic?
--Alterando a linha referente ao WHERE number_cards = 0 para >1 temos a tabela CLIENTS_CARDS_INFO_DEMO:
SELECT clients_no_cards_info.client_id, clients_no_cards_info.type, clients_no_cards_info.number_cards, clients_no_cards_info.birth_number, clients_no_cards_info.sex, demograph_corrigido.*
FROM(
	SELECT client_corrigido.client_id, clients_no_cards.type, clients_no_cards.number_cards, client_corrigido.birth_number, client_corrigido.sex, client_corrigido.district_id
	FROM (SELECT *
			FROM (SELECT disposition_corrigido.client_id
						,creditcard_corrigido.type
						,COUNT(creditcard_corrigido.card_id) AS number_cards
						FROM creditcard_corrigido
							RIGHT JOIN disposition_corrigido
							ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
							GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
							ORDER BY disposition_corrigido.client_id) as clients_cards
			WHERE number_cards > 0) AS clients_no_cards
	LEFT JOIN client_corrigido
	ON clients_no_cards.client_id = client_corrigido.client_id
	) AS clients_no_cards_info
LEFT JOIN demograph_corrigido
ON demograph_corrigido."A1" = clients_no_cards_info.district_id;

--Aplicando o agrupamento para a região e tipo de cartão.
--Para Junior temos:
SELECT "A3", type, SUM(number_cards)
FROM
	(SELECT clients_more_cards_info.client_id, clients_more_cards_info.type, clients_more_cards_info.number_cards, clients_more_cards_info.birth_number, clients_more_cards_info.sex, demograph_corrigido.*
	FROM(
		SELECT client_corrigido.client_id, clients_more_cards.type, clients_more_cards.number_cards, client_corrigido.birth_number, client_corrigido.sex, client_corrigido.district_id
		FROM (SELECT *
				FROM (SELECT disposition_corrigido.client_id
							,creditcard_corrigido.type
							,COUNT(creditcard_corrigido.card_id) AS number_cards
							FROM creditcard_corrigido
								RIGHT JOIN disposition_corrigido
								ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
								GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
								ORDER BY disposition_corrigido.client_id) as clients_cards
				WHERE number_cards > 0) AS clients_more_cards
		LEFT JOIN client_corrigido
		ON clients_more_cards.client_id = client_corrigido.client_id
		) AS clients_more_cards_info
	LEFT JOIN demograph_corrigido
	ON demograph_corrigido."A1" = clients_more_cards_info.district_id) AS clients_cards_info_demo
WHERE type = 'junior'
GROUP BY "A3", type
ORDER BY SUM(number_cards) DESC;

--Para classic temos:
SELECT "A3", type, SUM(number_cards)
FROM
	(SELECT clients_more_cards_info.client_id, clients_more_cards_info.type, clients_more_cards_info.number_cards, clients_more_cards_info.birth_number, clients_more_cards_info.sex, demograph_corrigido.*
	FROM(
		SELECT client_corrigido.client_id, clients_more_cards.type, clients_more_cards.number_cards, client_corrigido.birth_number, client_corrigido.sex, client_corrigido.district_id
		FROM (SELECT *
				FROM (SELECT disposition_corrigido.client_id
							,creditcard_corrigido.type
							,COUNT(creditcard_corrigido.card_id) AS number_cards
							FROM creditcard_corrigido
								RIGHT JOIN disposition_corrigido
								ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
								GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
								ORDER BY disposition_corrigido.client_id) as clients_cards
				WHERE number_cards > 0) AS clients_more_cards
		LEFT JOIN client_corrigido
		ON clients_more_cards.client_id = client_corrigido.client_id
		) AS clients_more_cards_info
	LEFT JOIN demograph_corrigido
	ON demograph_corrigido."A1" = clients_more_cards_info.district_id) AS clients_cards_info_demo
WHERE type = 'classic'
GROUP BY "A3", type
ORDER BY SUM(number_cards) DESC;
--Há mais oportunidades de upgrade na categoria Classic. South Moravia concentra a maioria dos classic (99 clientes, quase 10% dos clientes que usam cartão).

--Verificando os distritos dentro da South Moravia.
SELECT "A1", SUM(number_cards)
FROM(
	SELECT clients_no_cards_info.client_id, clients_no_cards_info.type, clients_no_cards_info.number_cards, clients_no_cards_info.birth_number, clients_no_cards_info.sex, demograph_corrigido.*
	FROM(
		SELECT client_corrigido.client_id, clients_no_cards.type, clients_no_cards.number_cards, client_corrigido.birth_number, client_corrigido.sex, client_corrigido.district_id
		FROM (SELECT *
				FROM (SELECT disposition_corrigido.client_id
							,creditcard_corrigido.type
							,COUNT(creditcard_corrigido.card_id) AS number_cards
							FROM creditcard_corrigido
								RIGHT JOIN disposition_corrigido
								ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
								GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
								ORDER BY disposition_corrigido.client_id) as clients_cards
				WHERE number_cards > 0) AS clients_no_cards
		LEFT JOIN client_corrigido
		ON clients_no_cards.client_id = client_corrigido.client_id
		) AS clients_no_cards_info
	LEFT JOIN demograph_corrigido
	ON demograph_corrigido."A1" = clients_no_cards_info.district_id)
	AS south_moravia_classic_clients
WHERE "A3" = 'south Moravia' AND type = 'classic'
GROUP BY "A1"
ORDER BY SUM(number_cards) DESC;
--Clientes Classic estão dispersos entre vários distritos da South Moravia

--Verificando os distritos com mais Classics:
SELECT "A1", type, SUM(number_cards)
FROM
	(SELECT clients_more_cards_info.client_id, clients_more_cards_info.type, clients_more_cards_info.number_cards, clients_more_cards_info.birth_number, clients_more_cards_info.sex, demograph_corrigido.*
	FROM(
		SELECT client_corrigido.client_id, clients_more_cards.type, clients_more_cards.number_cards, client_corrigido.birth_number, client_corrigido.sex, client_corrigido.district_id
		FROM (SELECT *
				FROM (SELECT disposition_corrigido.client_id
							,creditcard_corrigido.type
							,COUNT(creditcard_corrigido.card_id) AS number_cards
							FROM creditcard_corrigido
								RIGHT JOIN disposition_corrigido
								ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
								GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
								ORDER BY disposition_corrigido.client_id) as clients_cards
				WHERE number_cards > 0) AS clients_more_cards
		LEFT JOIN client_corrigido
		ON clients_more_cards.client_id = client_corrigido.client_id
		) AS clients_more_cards_info
	LEFT JOIN demograph_corrigido
	ON demograph_corrigido."A1" = clients_more_cards_info.district_id) AS clients_cards_info_demo
WHERE type = 'classic'
GROUP BY "A1", type
ORDER BY SUM(number_cards) DESC;
--Há mais oportunidades de upgrade no distrito 1.

--6.2. Onde estão os mais gastões (operações de "credit card withdraw") estão em qual região?
--Vamos joinar a tabela CLIENTS_CARDS_INFO_DEMO com a tabela TRANSACTIONS através do ACCOUNT_ID. Para isso necessitaremos joinar antes com DISPOSITION.
--Utilizaremos o LEFT JOIN pois também queremos puxar as pessoas que não realizaram transações para contabilizar ao indicador (afinal estamos ranqueando os mais "gastões").

SELECT clients_cards_Info_demo.*, disposition_corrigido.account_id
FROM(
	SELECT clients_no_cards_info.client_id, clients_no_cards_info.type, clients_no_cards_info.number_cards, clients_no_cards_info.birth_number, clients_no_cards_info.sex, demograph_corrigido.*
	FROM(
		SELECT client_corrigido.client_id, clients_no_cards.type, clients_no_cards.number_cards, client_corrigido.birth_number, client_corrigido.sex, client_corrigido.district_id
		FROM (SELECT *
				FROM (SELECT disposition_corrigido.client_id
							,creditcard_corrigido.type
							,COUNT(creditcard_corrigido.card_id) AS number_cards
							FROM creditcard_corrigido
								RIGHT JOIN disposition_corrigido
								ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
								GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
								ORDER BY disposition_corrigido.client_id) as clients_cards
				WHERE number_cards > 0) AS clients_no_cards
		LEFT JOIN client_corrigido
		ON clients_no_cards.client_id = client_corrigido.client_id
		) AS clients_no_cards_info
	LEFT JOIN demograph_corrigido
	ON demograph_corrigido."A1" = clients_no_cards_info.district_id
	) AS clients_cards_info_demo
LEFT JOIN disposition_corrigido
ON disposition_corrigido.client_id = clients_cards_info_demo.client_id;

--Dando LEFT JOIN agora em TRANSACTIONS_CORRIGIDO:
SELECT clients_cards_info_demo_account."A3", SUM(transactions_corrigido.amount)
FROM(
	SELECT clients_cards_Info_demo.*, disposition_corrigido.account_id
	FROM(
		SELECT clients_no_cards_info.client_id, clients_no_cards_info.type, clients_no_cards_info.number_cards, clients_no_cards_info.birth_number, clients_no_cards_info.sex, demograph_corrigido.*
		FROM(
			SELECT client_corrigido.client_id, clients_no_cards.type, clients_no_cards.number_cards, client_corrigido.birth_number, client_corrigido.sex, client_corrigido.district_id
			FROM (SELECT *
					FROM (SELECT disposition_corrigido.client_id
								,creditcard_corrigido.type
								,COUNT(creditcard_corrigido.card_id) AS number_cards
								FROM creditcard_corrigido
									RIGHT JOIN disposition_corrigido
									ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
									GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
									ORDER BY disposition_corrigido.client_id) as clients_cards
					WHERE number_cards > 0) AS clients_no_cards
			LEFT JOIN client_corrigido
			ON clients_no_cards.client_id = client_corrigido.client_id
			) AS clients_no_cards_info
		LEFT JOIN demograph_corrigido
		ON demograph_corrigido."A1" = clients_no_cards_info.district_id
		) AS clients_cards_info_demo
	LEFT JOIN disposition_corrigido
	ON disposition_corrigido.client_id = clients_cards_info_demo.client_id
	) AS clients_cards_info_demo_account
LEFT JOIN transactions_corrigido
ON transactions_corrigido.account_id = clients_cards_info_demo_account.account_id
WHERE clients_cards_info_demo_account.type = 'classic' AND transactions_corrigido.operation = 'CREDIT CARD WITHDRAWAL'
GROUP BY clients_cards_info_demo_account."A3", transactions_corrigido.operation
ORDER BY SUM(transactions_corrigido.amount) DESC;
-- Maior quantidade de operações “credit card withdrawl” se concentram na North Moravia


--Verificando os distritos onde temos clientes Classic por "credit card withdrawal":
SELECT clients_cards_info_demo_account."A1", SUM(transactions_corrigido.amount)
FROM(
	SELECT clients_cards_Info_demo.*, disposition_corrigido.account_id
	FROM(
		SELECT clients_no_cards_info.client_id, clients_no_cards_info.type, clients_no_cards_info.number_cards, clients_no_cards_info.birth_number, clients_no_cards_info.sex, demograph_corrigido.*
		FROM(
			SELECT client_corrigido.client_id, clients_no_cards.type, clients_no_cards.number_cards, client_corrigido.birth_number, client_corrigido.sex, client_corrigido.district_id
			FROM (SELECT *
					FROM (SELECT disposition_corrigido.client_id
								,creditcard_corrigido.type
								,COUNT(creditcard_corrigido.card_id) AS number_cards
								FROM creditcard_corrigido
									RIGHT JOIN disposition_corrigido
									ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
									GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
									ORDER BY disposition_corrigido.client_id) as clients_cards
					WHERE number_cards > 0) AS clients_no_cards
			LEFT JOIN client_corrigido
			ON clients_no_cards.client_id = client_corrigido.client_id
			) AS clients_no_cards_info
		LEFT JOIN demograph_corrigido
		ON demograph_corrigido."A1" = clients_no_cards_info.district_id
		) AS clients_cards_info_demo
	LEFT JOIN disposition_corrigido
	ON disposition_corrigido.client_id = clients_cards_info_demo.client_id
	) AS clients_cards_info_demo_account
LEFT JOIN transactions_corrigido
ON transactions_corrigido.account_id = clients_cards_info_demo_account.account_id
WHERE clients_cards_info_demo_account.type = 'classic' AND transactions_corrigido.operation = 'CREDIT CARD WITHDRAWAL'
GROUP BY clients_cards_info_demo_account."A1", transactions_corrigido.operation
ORDER BY SUM(transactions_corrigido.amount) DESC;
--É evidente que a importância do distrito 1 de Praga é mais relevante para uma iniciativa de publicidade.

--7. O gasto médio por região:
SELECT clients_cards_info_demo_account."A1", SUM(transactions_corrigido.amount)/COUNT(transactions_corrigido.amount)
FROM(
	SELECT clients_cards_Info_demo.*, disposition_corrigido.account_id
	FROM(
		SELECT clients_no_cards_info.client_id, clients_no_cards_info.type, clients_no_cards_info.number_cards, clients_no_cards_info.birth_number, clients_no_cards_info.sex, demograph_corrigido.*
		FROM(
			SELECT client_corrigido.client_id, clients_no_cards.type, clients_no_cards.number_cards, client_corrigido.birth_number, client_corrigido.sex, client_corrigido.district_id
			FROM (SELECT *
					FROM (SELECT disposition_corrigido.client_id
								,creditcard_corrigido.type
								,COUNT(creditcard_corrigido.card_id) AS number_cards
								FROM creditcard_corrigido
									RIGHT JOIN disposition_corrigido
									ON disposition_corrigido.disp_id = creditcard_corrigido.disp_id
									GROUP BY creditcard_corrigido.type, disposition_corrigido.client_id
									ORDER BY disposition_corrigido.client_id) as clients_cards
					WHERE number_cards > 0) AS clients_no_cards
			LEFT JOIN client_corrigido
			ON clients_no_cards.client_id = client_corrigido.client_id
			) AS clients_no_cards_info
		LEFT JOIN demograph_corrigido
		ON demograph_corrigido."A1" = clients_no_cards_info.district_id
		) AS clients_cards_info_demo
	LEFT JOIN disposition_corrigido
	ON disposition_corrigido.client_id = clients_cards_info_demo.client_id
	) AS clients_cards_info_demo_account
LEFT JOIN transactions_corrigido
ON transactions_corrigido.account_id = clients_cards_info_demo_account.account_id
WHERE clients_cards_info_demo_account.type = 'classic' AND transactions_corrigido.operation = 'CREDIT CARD WITHDRAWAL'
GROUP BY clients_cards_info_demo_account."A1", transactions_corrigido.operation
ORDER BY SUM(transactions_corrigido.amount)/COUNT(transactions_corrigido.amount) DESC;