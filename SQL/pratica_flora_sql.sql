#CREATE schema pratica_flora;
use pratica_flora;

##upload e normalizaçao das planilhas
SELECT * FROM flora_pedidos;

SELECT * FROM flora_produtos;

SELECT * from flora_clientes;

SELECT * FROM flora_fornecedores;

#remoção de acentos no VS code
#tipos de dados foram alterados na ferramenta
#Tabela pagamento foi gerada em python

#Perguntas de negócio:

#1. Quantos são e quem são os clientes estão inadimplentes? 

SELECT
COUNT(id_cliente) inadimplentes
FROM flora_pagamentos
WHERE Status = 'em aberto';


#2. Quais são os boletos vencidos?
SELECT
pgt.id_cliente as cliente,
P.valor_total,
p.data_pedido as data_boleto
FROM flora_pagamentos pgt
INNER JOIN flora_pedidos p
ON pgt.id_cliente = p.id_cliente
WHERE pgt.status = 'em aberto' AND p.data_pedido != current_date();

#3. Qual o valor devido por cliente? 

SELECT
pgt.id_cliente as cliente,
cli.nome_cliente,
SUM(p.valor_total) as valor_devido
FROM flora_pagamentos pgt
INNER JOIN flora_pedidos p
ON pgt.id_cliente = p.id_cliente
INNER JOIN flora_clientes cli
ON p.id_cliente = cli.id_cliente
WHERE pgt.status = 'em aberto'
GROUP BY pgt.id_cliente;

#4. Quais são os produtos mais vendidos
SELECT
p.nome_produto nome,
SUM(pe.quantidade) quantidade
FROM flora_pedidos pe
INNER JOIN flora_produtos p
ON pe.id_produto = p.id_produto
GROUP BY nome
ORDER BY quantidade DESC;

#5. Quais foram os produtos mais vendidos em cada estação de 2022?

SELECT
produtos.nome_produto nome,
CASE
WHEN pedidos.data_pedido BETWEEN '2022-12-22' AND '2022-12-31' THEN 'verao'
WHEN pedidos.data_pedido BETWEEN '2022-01-01' AND '2022-03-19' THEN 'verao'
WHEN pedidos.data_pedido BETWEEN '2022-03-20' AND '2022-06-20' THEN 'outono'
WHEN pedidos.data_pedido BETWEEN '2022-06-21' AND '2022-09-22' THEN 'inverno'
WHEN pedidos.data_pedido BETWEEN '2022-09-23' AND '2022-12-21' THEN 'primavera'
ELSE 'null'
END estacao,
SUM(pedidos.quantidade) quantidade
FROM flora_pedidos pedidos
INNER JOIN flora_produtos produtos
ON pedidos.id_produto = produtos.id_produto
GROUP BY estacao, nome
ORDER BY estacao, quantidade DESC;

#6. Quais são os produtos mais vendidos mês a mês

SELECT
MONTH(pe.data_pedido) mes,
p.nome_produto,
SUM(pe.quantidade) as quantidade
FROM flora_pedidos pe
INNER JOIN flora_produtos p
ON pe.id_produto = p.id_produto
GROUP BY pe.data_pedido, p.nome_produto
ORDER BY mes ASC, quantidade DESC;

#7. Qual a margem de lucro de cada produto
CREATE VIEW margem_lucro AS (
SELECT
nome_produto nome,
ROUND((preco_produto - custos)/preco_produto, 2) as percentual_lucro
FROM flora_produtos
ORDER BY percentual_lucro DESC);
SELECT * FROM margem_lucro;

#8. Quantas unidades de  cada produto foram vendidas no decorrer do ano
SELECT
produto.nome_produto nome,
SUM(pedidos.quantidade) quantidade
FROM flora_pedidos pedidos
INNER JOIN flora_produtos produto
ON pedidos.id_produto = produto.id_produto
GROUP BY nome;

#9. Qual a receita gerada por cada produto no decorrer do ano

CREATE VIEW view_receita AS(
SELECT
produto.nome_produto nome,
SUM((pedidos.quantidade)*(produto.preco_produto)) receita_total
FROM flora_pedidos pedidos
INNER JOIN flora_produtos produto
ON pedidos.id_produto = produto.id_produto
GROUP BY nome);

SELECT * FROM view_receita; 

#10. Qual foi o lucro que cada produto gerou ao decorrer do ano?
CREATE VIEW view_lucro AS(
SELECT
produto.nome_produto nome,
ROUND(sum((produto.preco_produto - produto.custos)*(pedidos.quantidade))) as lucro_bruto
FROM flora_produtos produto
INNER JOIN flora_pedidos pedidos
ON produto.id_produto = pedidos.id_produto
GROUP BY nome);
select * from view_lucro;

#10. Quais produtos devemos aplicar reajuste de preço e qual o percentual de reajuste?
SELECT 
r.nome,
produtos.preco_produto preco_antigo,
produtos.custos custo,
ROUND(produtos.preco_produto - produtos.custos,2) lucro_bruto,
percentual_lucro,
case when percentual_lucro <= 65 then 'aplicar reajuste'
end reajuste,
case when percentual_lucro < 65 then ROUND((produtos.custos/0.35),2)
else produtos.preco_produto
end novo_preco
FROM view_receita r
INNER JOIN view_lucro l
ON r.nome = l.nome
INNER JOIN margem_lucro
ON l.nome = margem_lucro.nome
INNER JOIN flora_produtos produtos
on l.nome = produtos.nome_produto
ORDER BY percentual_lucro ASC;

# 11. Qual o grupo de empreendimentos que mais gasta?
CREATE VIEW vendas_setor AS
(SELECT
cli.empreendimento setor,
sum(p.valor_total) valor_total
FROM pratica_flora.flora_pedidos p
INNER JOIN pratica_flora.flora_clientes cli
ON p.id_cliente = cli.id_cliente
GROUP BY setor
ORDER BY valor_total DESC);

# 12 Qual o ticket médio por setor?
SELECT
cli.empreendimento,
count(cli.nome_cliente) qtd_empresas,
vs.valor_total,
ROUND(vs.valor_total/count(cli.nome_cliente),2) ticket_medio
FROM pratica_flora.flora_clientes cli
INNER JOIN vendas_setor vs
ON vs.setor = cli.empreendimento
GROUP BY cli.empreendimento
ORDER BY ticket_medio DESC;
