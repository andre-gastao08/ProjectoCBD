--Coisa que acontece no momento que deviam acontecer coisas--
--temos de criar um schema a cada tabela 
USE master
GO

IF (db_id('CBDLeiloes') is not null)
	Drop database CBDLeiloes;
Go

CREATE DATABASE CBDLeiloes;
Go

If DB_ID('CBDLeiloes') is null
	Raiserror('BD n�o criada',16,1)
Go

Use CBDLeiloes
Go

Create Schema SchemaProduto;
Go
Create Schema SchemaUtilizador;
Go
Create Schema SchemaLicitacao;
Go


--Cria��o de coisas onde se metem outras coisas--
Create table schemaUtilizador.Utilizador (
	UtilizadorId int identity(1,1) not null,
	UtilizadorNome varchar(50),
	UtilizadorSenha varchar(50),	
	UtilizadorEmail varchar(255)
	constraint mail_constraint
		check (UtilizadorEmail like '%@%.%') ,
	UtilizadorDataRegisto date,
	UtilizadorDataNascimento date,
	UtilizadorTelefone varchar(15)
	constraint uk_Telefone
		unique (UtilizadorTelefone )
	constraint CK_Telelfone
		check (UtilizadorTelefone like'[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
);

Create table SchemaUtilizador.Seguidor (
	SeguidorTableId  int identity(1,1) not null,
	SeguidorSeguidorID int not null,
	SeguidorSeguidoID int not null
);
--por norma o id tem de ser em primeiro lugar

Create table SchemaProduto.Produto (
	ProdutoId int identity(1,1) not null, 
	ProdutoNome varchar(50),
	ProdutoDescricao varchar(255),
	ProdutoValorMinVenda decimal(9,2),
	ProdutoDataLimiteLeilao date,
	ProdutoUtilizadorID int not null
);

Create table SchemaLicitacao.Licitacao (
	LicitacaoId int identity(1,1) not null,
	LicitacaoData date,
	LicitacaoValorMax decimal(9,2),
	LicitacaoValorActual decimal(9,2),
	LicitacaoProdutoID int not null,
	LicitacaoUtilizadorID int not null
);

Create table SchemaUtilizador.SeguirProduto (
	SeguirProdutoTableId int identity(1,1) not null,
	SeguirProdutoProdutoId int not null,
	SeguirProdutoUtilizadorID int not null
);
Go

--Adicionadas restri��es �s coisas para n�o se armarem em espertas ou restri��es de chaves primarias--

Alter table SchemaUtilizador.Utilizador add constraint pk_Utilizador primary key (UtilizadorId);

Alter table SchemaUtilizador.Seguidor add constraint pk_Seguidor primary key (SeguidorTableId);

Alter table SchemaProduto.Produto add constraint pk_Produto primary key (ProdutoId);

Alter table SchemaUtilizador.SeguirProduto add constraint pk_SeguirProduto primary key (SeguirProdutoTableId);

Alter table SchemaLicitacao.Licitacao add constraint pk_Licitacao primary key (LicitacaoId);

Go

--Adicionadas mais restri��es porque restri��es nunca s�o de mais ou as restri��es de chaves estrangeiras--

Alter table SchemaProduto.Produto add constraint Produto_fk_Utilizador
            foreign key (ProdutoUtilizadorID) references SchemaUtilizador.Utilizador(UtilizadorId) on delete cascade;

Alter table SchemaUtilizador.Seguidor add constraint Seguidor_fk_Utilizador
            foreign key (SeguidorSeguidorID) references SchemaUtilizador.Utilizador(UtilizadorId);

Alter table SchemaUtilizador.Seguidor add constraint Seguido_fk_Utilizador
            foreign key (SeguidorSeguidoID) references SchemaUtilizador.Utilizador(UtilizadorId);

Alter table SchemaUtilizador.SeguirProduto add constraint SeguirProduto_fk_Produto
            foreign key (SeguirProdutoProdutoID) references SchemaProduto.Produto(ProdutoId);

Alter table SchemaUtilizador.SeguirProduto add constraint SeguirProduto_fk_Utilizador
            foreign key (SeguirProdutoUtilizadorID) references SchemaUtilizador.Utilizador(UtilizadorId);

Alter table SchemaLicitacao.Licitacao add constraint Licitacao_fk_Produto
            foreign key (LicitacaoProdutoID) references SchemaProduto.Produto(ProdutoId) ;

Alter table SchemaLicitacao.Licitacao add constraint Licitacao_fk_Utilizador
            foreign key (LicitacaoUtilizadorID) references SchemaUtilizador.Utilizador(UtilizadorId) on delete cascade;



Go

--Fun��es que devem funcionar.--
IF OBJECT_ID (N'SchemaUtilizador.funcPassToHash', N'TF') IS NOT NULL
    DROP FUNCTION SchemaUtilizador.funcPassToHash;
GO
--Converte a password para uma hash--/* sofreu a altera��o na aula de Lab*/
CREATE FUNCTION SchemaUtilizador.funcPassToHash (@pass NVARCHAR)
RETURNS NVARCHAR(32)
AS
BEGIN
	DECLARE @hash Nvarchar(32)
	set @hash= CONVERT(NVARCHAR(32), HASHBYTES('SHA1', @pass), 2)
	return @hash
END;
GO

select SchemaUtilizador.funcPassToHash('OAS53QMI5JS')/*exemplo que o mais precisa-se no projeto*/

IF OBJECT_ID (N'SchemaUtilizador.funcIdadeTens', N'TF') IS NOT NULL
    DROP FUNCTION SchemaUtilizador.funcIdadeTens;
GO
--Calcular a idade a partir da data --/* sofreu a altera��o na aula de Lab*/
CREATE FUNCTION SchemaUtilizador.funcIdadeTens(@userId int)
RETURNS int
AS
BEGIN
	DECLARE @idade int
	DECLARE @dataNasc date

	--reaver data nascimento do utilizador especificado
	select @dataNasc = UtilizadorDataNascimento from SchemaUtilizador.Utilizador where UtilizadorId = @userId

	--mediante data obtida, calcular idade em rela��o � data atual
	select @idade = datediff(YYYY,@dataNasc, GETDATE()) 
	
	if(@idade is NULL)
		return 0

	return @idade
END
GO


select u.UtilizadorNome, u.UtilizadorDataNascimento, SchemaUtilizador.funcIdadeTens(u.UtilizadorId) as Idade  from SchemaUtilizador.Utilizador u 


IF OBJECT_ID (N'SchemaUtilizador.funcPassConfirm ', N'TF') IS NOT NULL
    DROP FUNCTION  SchemaUtilizador.funcPassConfirm ;
GO
--Compara a pass do utilizador (usar em logins)--
CREATE FUNCTION SchemaUtilizador.funcPassConfirm (@user int, @pass NVARCHAR)
RETURNS int
AS
BEGIN
	DECLARE @returnVal Nvarchar(500)
	--SET NOCOUNT ON  
	if exists(select UtilizadorId, UtilizadorSenha from SchemaUtilizador.Utilizador 
	where UtilizadorId=@user and UtilizadorSenha= SchemaUtilizador.funcPassToHash(@pass))
  set @returnVal=1
  else
  set @returnVal=0
	return @returnVal
END;
Go
--Procedimento para colocar um produto � venda--

Create proc SchemaProduto.procVenderProd
			(@ProdDesc varchar(100), @ProdNome varchar(50), @ProdDataLimite varchar(50), @ProdValorMin int)
as
SET NOCOUNT ON
Insert into SchemaProduto.Produto (ProdutoNome,ProdutoDescricao,  ProdutoDataLimiteLeilao, ProdutoValorMinVenda )
		values (@ProdNome, @ProdDesc, @ProdDataLimite, @ProdValorMin)
Go
--Procedimento para licitar num produto--
Create proc SchemaProduto.procLicitarProd
			(@userid int, @prodid int, @licitaval int)
as
SET NOCOUNT ON
Insert into SchemaLicitacao.Licitacao(LicitacaoUtilizadorID,LicitacaoProdutoID,LicitacaoValorMax)
			values(@userid, @prodid,@licitaval)
Go


								
--Inser��o de dados  utilizador e garedos de  forma automatica.--

INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Dolan Moore','yI1nsH3ojV6fLB5c','placerat.orci.lacus@maurisaliquam.co.uk','2016-01-18','1956-01-04','967132109');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Myles Lowery','GG6opA4boD6ufR2h','Quisque.fringilla.euismod@Phasellus.org','2015-08-12','1956-07-14','941063393');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Yolanda Bailey','wK0zLU5pVX2suD5t','sem@nonmassanon.ca','2016-01-31','1937-02-03','976457812');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Aristotle Hurley','gE1qlB0rbF1plX7r','nunc@egestaslacinia.net','2016-05-25','1976-06-05','988891372');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Iliana Rhodes','GY7fWM6aMU7mAX7k','Cras@auctorMauris.org','2015-11-18','1978-08-31','936929381');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Magee Ramos','TN1tYS8qEV9rBS2x','Quisque@adipiscingelitEtiam.com','2016-08-07','1974-02-08','947118957');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Michael Quinn','eA5paJ0wGD1wFJ7k','Nunc.ut@Aliquam.ca','2016-07-29','1952-01-07','977587097');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Valentine Clarke','mL2oQC8evX2mmQ4d','metus.In.nec@interdumenim.com','2015-03-25','1952-09-21','960848668');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Nigel Espinoza','SY8lHZ1wqG1pzO3j','Integer.tincidunt@sodalesnisimagna.com','2016-07-29','1972-08-25','992130998');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Allegra Payne','wJ9buY0uQH6kgP2k','lectus.rutrum@tincidunt.net','2015-08-05','1983-10-21','999060901');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Lawrence Guzman','eR3byB7nFX5qtC9b','in.felis.Nulla@quislectus.net','2016-07-09','1948-01-15','971869678');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Teegan Gilbert','PA3oKU9tDE7jOA9w','ac@ultricesposuere.edu','2016-07-10','1944-03-09','984515189');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Velma Campbell','sZ8iTH3wfD8rEZ0t','enim@laoreet.edu','2015-11-03','1975-11-02','975146642');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Jaden Mcfadden','RT9ldG5apK6jjN3a','et.magna@semutdolor.org','2015-06-18','1985-07-08','981881981');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Athena Lynn','lE6rbJ5waK7wsY0t','Duis@pedesagittisaugue.ca','2015-10-09','1954-05-19','914012215');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Honorato Howell','AM2oMQ8mWS9wsI7s','Nulla.facilisi@magnisdisparturient.net','2016-04-17','1943-07-13','939685071');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Nina Hughes','VI4avN1iYU7mxB7b','elementum@tinciduntnunc.co.uk','2015-11-19','1981-10-13','967501987');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Yasir Albert','FJ4cqQ2mdA8kmZ2v','nec.cursus.a@Morbinequetellus.com','2015-12-15','1973-12-02','985213911');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Uta Bell','lD6xiM5vtI3hBQ4a','lacus.Quisque@eliterat.edu','2015-04-20','1970-08-22','920805323');
INSERT INTO SchemaUtilizador.Utilizador([UtilizadorNome],[UtilizadorSenha],[UtilizadorEmail],[UtilizadorDataRegisto],[UtilizadorDataNascimento],[UtilizadorTelefone]) VALUES('Josephine Alford','YN8sLG0juU6cMI8z','quam@vulputateposuerevulputate.org','2016-02-18','1982-03-19','968881126');

--select * from SchemaUtilizador.Utilizador;

--inser��o de dados de seguidor---

INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(3,13);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(8,12);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(13,7);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(4,8);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(1,10);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(12,20);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(12,19);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(16,11);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(19,7);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(20,14);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(4,1);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(8,11);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(19,19);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(10,3);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(13,7);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(6,5);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(9,5);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(15,7);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(16,15);
INSERT INTO SchemaUtilizador.Seguidor([SeguidorSeguidorID],[SeguidorSeguidoID]) VALUES(5,4);

--select * from SchemaUtilizador.Seguidor;

--inser��o de dados do Produto--
INSERT INTO SchemaProduto.Produto([ProdutoNome],ProdutoDescricao,[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Fusce Aliquet Magna Industries','dignissim lacus. Aliquam rutrum lorem ac risus. Morbi metus. Vivamus euismod urna. Nullam lobortis quam a felis ullamcorper viverra. Maecenas', 12.91,'2006-06-17',11);
INSERT INTO SchemaProduto.Produto([ProdutoNome],ProdutoDescricao,[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Magna Industries','Donec egestas. Aliquam nec enim. Nunc ut erat. Sed nunc est, mollis non, cursus non, egestas a, dui. Cras pellentesque.',85.96,'2011-02-15',20);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Cursus In Hendrerit PC','id enim. Curabitur massa. Vestibulum accumsan neque et nunc. Quisque ornare tortor at risus. Nunc ac sem ut dolor dapibus',39.45,'2013-05-21',19);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Pede Suspendisse Dui Corporation','felis ullamcorper viverra. Maecenas iaculis aliquet diam. Sed diam lorem, auctor quis, tristique ac, eleifend vitae, erat. Vivamus nisi. Mauris',56.35,'2013-07-06',16);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Nulla Vulputate Dui PC','nunc id enim. Curabitur massa. Vestibulum accumsan neque et nunc. Quisque ornare tortor at risus. Nunc ac sem ut dolor',40.36,'2011-04-13',19);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Commodo Hendrerit Donec Foundation','dui, semper et, lacinia vitae, sodales at, velit. Pellentesque ultricies dignissim lacus. Aliquam rutrum lorem ac risus. Morbi metus. Vivamus',19.35,'2012-06-16',19);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Mauris Inc.','metus urna convallis erat, eget tincidunt dui augue eu tellus. Phasellus elit pede, malesuada vel, venenatis vel, faucibus id, libero.',74.51,'2013-08-23',20);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Odio Tristique Pharetra Corp.','nibh. Quisque nonummy ipsum non arcu. Vivamus sit amet risus. Donec egestas. Aliquam nec enim. Nunc ut erat. Sed nunc',25.05,'2006-10-23',1);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Nec Luctus LLC','Fusce fermentum fermentum arcu. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Phasellus ornare. Fusce',59.74,'2009-04-29',2);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Cras Convallis Institute','id sapien. Cras dolor dolor, tempus non, lacinia at, iaculis quis, pede. Praesent eu dui. Cum sociis natoque penatibus et',5.33,'2009-12-13',3);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Ut Tincidunt Company','pharetra. Quisque ac libero nec ligula consectetuer rhoncus. Nullam velit dui, semper et, lacinia vitae, sodales at, velit. Pellentesque ultricies',95.56,'2006-03-25',17);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Est Nunc LLC','elit, dictum eu, eleifend nec, malesuada ut, sem. Nulla interdum. Curabitur dictum. Phasellus in felis. Nulla tempor augue ac ipsum.',28.57,'2011-06-06',1);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Fringilla Purus Mauris Inc.','orci. Phasellus dapibus quam quis diam. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Fusce',97.01,'2006-12-05',1);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Neque Pellentesque Massa Incorporated','vitae, posuere at, velit. Cras lorem lorem, luctus ut, pellentesque eget, dictum placerat, augue. Sed molestie. Sed id risus quis',74.67,'2005-12-17',6);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Imperdiet Ullamcorper Duis LLP','netus et malesuada fames ac turpis egestas. Fusce aliquet magna a neque. Nullam ut nisi a odio semper cursus. Integer',77.26,'2005-05-02',10);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Urna Convallis Erat Industries','est. Mauris eu turpis. Nulla aliquet. Proin velit. Sed malesuada augue ut lacus. Nulla tincidunt, neque vitae semper egestas, urna',55.40,'2009-04-29',17);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Nec Company','leo, in lobortis tellus justo sit amet nulla. Donec non justo. Proin non massa non ante bibendum ullamcorper. Duis cursus,',11.54,'2009-05-27',16);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Pede Limited','Curabitur ut odio vel est tempor bibendum. Donec felis orci, adipiscing non, luctus sit amet, faucibus ut, nulla. Cras eu',84.06,'2011-03-09',17);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('At Iaculis Quis Company','ac metus vitae velit egestas lacinia. Sed congue, elit sed consequat auctor, nunc nulla vulputate dui, nec tempus mauris erat',28.63,'2007-02-25',6);
INSERT INTO SchemaProduto.Produto([ProdutoNome],[ProdutoDescricao],[ProdutoValorMinVenda],[ProdutoDataLimiteLeilao],[ProdutoUtilizadorID]) VALUES('Malesuada Fames Foundation','venenatis vel, faucibus id, libero. Donec consectetuer mauris id sapien. Cras dolor dolor, tempus non, lacinia at, iaculis quis, pede.',47.06,'2005-11-26',10);

select * from SchemaProduto.Produto;