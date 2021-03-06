/****** Object:  Database [MotoApp_v1]    Script Date: 06/11/2015 11:15:02 ******/
CREATE DATABASE [MotoApp_v1]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'MotoApp_v1', FILENAME = N'C:\Databases\MotoApp_v1.mdf' , SIZE = 19456KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'MotoApp_v1_log', FILENAME = N'C:\Databases\MotoApp_v1_log.ldf' , SIZE = 3136KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [MotoApp_v1] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [MotoApp_v1].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [MotoApp_v1] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [MotoApp_v1] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [MotoApp_v1] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [MotoApp_v1] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [MotoApp_v1] SET ARITHABORT OFF 
GO
ALTER DATABASE [MotoApp_v1] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [MotoApp_v1] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [MotoApp_v1] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [MotoApp_v1] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [MotoApp_v1] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [MotoApp_v1] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [MotoApp_v1] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [MotoApp_v1] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [MotoApp_v1] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [MotoApp_v1] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [MotoApp_v1] SET  DISABLE_BROKER 
GO
ALTER DATABASE [MotoApp_v1] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [MotoApp_v1] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [MotoApp_v1] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [MotoApp_v1] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [MotoApp_v1] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [MotoApp_v1] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [MotoApp_v1] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [MotoApp_v1] SET RECOVERY FULL 
GO
ALTER DATABASE [MotoApp_v1] SET  MULTI_USER 
GO
ALTER DATABASE [MotoApp_v1] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [MotoApp_v1] SET DB_CHAINING OFF 
GO
ALTER DATABASE [MotoApp_v1] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [MotoApp_v1] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'MotoApp_v1', N'ON'
GO
/****** Object:  StoredProcedure [dbo].[PA_BPM_INS_Documento]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		Valentys Ltda. (Gale Starter Project)
-- Create date: 2015.07.06
-- Description:	Inserta un Documento de Negocio 
--				y devuelve su identificador (GUID)
-- =================================================================
CREATE PROCEDURE [dbo].[PA_BPM_INS_Documento]
	@ENTI_Token				UNIQUEIDENTIFIER,
	@TIDO_Codigo			INT,
	@ESTA_Codigo			INT,
	@DOCU_Token				UNIQUEIDENTIFIER OUTPUT 
AS	
BEGIN
	DECLARE @ENTI_Codigo			INT = dbo.FN_OBT_ENTI_Codigo(@ENTI_Token);

	----[ EXTRAER EL CORRELATIVO DEL DOCUMENTO
	DECLARE @DOCU_contador		INT = (SELECT COUNT(*) FROM [TB_BPM_Documento] DOCU WHERE DOCU.DOCU_TIDO_Codigo = @TIDO_Codigo) + 1;
	DECLARE @TIDO_Identificador	CHAR(4) = (SELECT TOP 1 TIDO.TIDO_Identificador FROM TB_BPM_TipoDocumento TIDO WHERE TIDO.TIDO_Codigo = @TIDO_Codigo);
	DECLARE @DOCU_Identificador	CHAR(9) = CONCAT(@TIDO_Identificador,'-',REPLACE(STR(@DOCU_contador, 4), SPACE(1), '0'));

	INSERT INTO [TB_BPM_Documento]
    (
        [DOCU_TIDO_Codigo],
        [DOCU_ENTI_Codigo],
        [DOCU_ESTA_Codigo],
		[DOCU_Identificador]         
	)
	VALUES
    (
        @TIDO_Codigo,
        @ENTI_Codigo,
        @ESTA_Codigo,
		@DOCU_Identificador
	)

	----------------------------------------------------------------------
	SELECT 
		@DOCU_Token = DOCU.DOCU_Token
	FROM
		TB_BPM_Documento DOCU
	WHERE
		DOCU.DOCU_Codigo = SCOPE_IDENTITY();
	----------------------------------------------------------------------
END


















GO
/****** Object:  StoredProcedure [dbo].[PA_BPM_INS_Transaccionar]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =================================================================
-- Author:		Valentys Ltda. (Gale Starter Project)
-- Create date: 2015.07.06
-- Description:	Ejecuta una acción de transición para un 
--				documento especifico, pasando a un estado nuevo de 
--				acuerdo a su estado inicial
-- =================================================================
CREATE PROCEDURE [dbo].[PA_BPM_INS_Transaccionar]
	@DOCU_Token				UNIQUEIDENTIFIER,
	@ENTI_Token				UNIQUEIDENTIFIER,		-- ENTIDAD QUE ENVIA LA ACCION
	@TRAN_Identificador		CHAR(4),				-- IDENTIFICADOR DE LA TRANSACCION
	@BITA_Observacion		VARCHAR(5000),
	@ListarDestinatarios	BIT = 1					-- SI @ListarDestinarios = 1 ,SE DEVUELVE EL LISTADO DE CORREOS A NOTIFICAR Y SU PLANTILLA
AS	
BEGIN
	----------------------------------------------------------------------------------------
	DECLARE @TRANNAME				VARCHAR(20) = 'TRANSAC';
	DECLARE @ENTI_Codigo			INT = dbo.FN_OBT_ENTI_Codigo(@ENTI_Token);	-- ENTIDAD QUE EJECUTA LA ACCION (EJEMPLO: USUARIO , PERFIL, ETC)
	DECLARE @DOCU_Codigo			INT = dbo.FN_OBT_DOCU_Codigo(@DOCU_Token);	-- DOCUMENTO A PROCESAR
	DECLARE @TRAN_Codigo			INT = NULL;									-- CODIGO IDENTIFICADOR DE LA TRANSICION
	DECLARE @CONTADOR_TAREAS		INT	= 0;									-- CONTADOR DE PENDIENTES ACTUALES PARA EL DOCUMENTO
	DECLARE @ESTA_Codigo_Final		INT = NULL;									-- ESTADO FINAL
	DECLARE @ENTI_Codigo_Destino	INT;										-- ENTIDAD(ES) DESTINTO AL CUAL SE ENVIARA EL O LOS PENDIENTES DE BPM
	DECLARE @PEND_Url				VARCHAR(2000) = NULL;						-- URL AL CUAL REDIRECCIONAR EL PENDIENTE AL HACER CLICK
	DECLARE @Destinatarios			TABLE (ENTI_Codigo INT);					-- TABLA QUE CONTENDRA LAS ENTIDADES A ENVIAR POR LA BPM
	----------------------------------------------------------------------------------------
	--- CONTADOR DE EXISTENCIA DE REGISTRO DE TAREAS PENDIENTES
	SELECT 
		@CONTADOR_TAREAS		= COUNT(*)
	FROM
		TB_BPM_Tarea TARE
	WHERE
		TARE.TARE_DOCU_Codigo	=	@DOCU_Codigo;
	----------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------
	--- BUSCA LA TRANSICION Y SU CONFIGURACION
	SELECT 
		@TRAN_Codigo			=	TRNA.TRAN_Codigo,
		@ESTA_Codigo_Final		=	TRNA.TRAN_ESTA_Codigo_Final,
		@PEND_Url				=	TRNA.TRAN_Url,
		@ENTI_Codigo			=	TRNA.ENTI_Codigo
	FROM
		TB_BPM_TipoDocumento	TIDO INNER JOIN 
		TB_BPM_Transicion		TRNA ON TRNA.TRAN_TIDO_Codigo = TIDO.TIDO_Codigo AND 
		TRNA.TRAN_Identificador	= @TRAN_Identificador AND
		TIDO.TIDO_Codigo		= (SELECT TOP 1 
										DOCU.DOCU_TIDO_Codigo 
									FROM 
										TB_BPM_Documento DOCU 
									WHERE 
										DOCU.DOCU_Codigo = @DOCU_Codigo);
	----------------------------------------------------------------------------------------

	--- PROCEDIMIENTOS AUXILIARES QUE SE DEBEN EJECUTAR AL PROCESAR EL DOCUMENTO
	DECLARE AUX_PROCEDIMIENTOS CURSOR FOR (	SELECT 
												CTRN.CTRN_Procedimiento 
											FROM 
												TB_BPM_TransicionAuxiliar CTRN 
											WHERE 
												CTRN.CTRN_TRAN_Codigo = @TRAN_Codigo);

	--- NOTIFICACIONES A ENVIAR A LAS DISTINTAS ENTIDADES
	DECLARE AUX_NOTIFICACIONES CURSOR FOR (	SELECT 
												CNOT.CNOT_TINO_Codigo, 
												CNOT.CNOT_Plantilla
											FROM  
												TB_BPM_NotificacionTransicion CNOT
											WHERE 
												CNOT.CNOT_TRAN_Codigo = @TRAN_Codigo);
	
	--- INSERTAMOS LA(S) ENTIDAD(ES) A LOS CUALES DEBERIAN ENVIARSE LOS PENDIENTES, CORREOS y NOTIFICACIONES
	INSERT INTO @Destinatarios
	SELECT 
		T.ENTI_Codigo
	FROM
		dbo.FN_BPM_OBT_DestinatariosTarea(@DOCU_Codigo, @ENTI_Codigo) T 
	
	BEGIN TRAN @TRANNAME
		BEGIN TRY

		----------------------------------------------------------------------------------------		
		--- INSERTA EL REGISTRO EN BITACORA
		INSERT INTO [TB_BPM_Bitacora]
		(
			[BITA_DOCU_Codigo]
			,[BITA_ESTA_Codigo]
			,[BITA_ENTI_Codigo]
			,[BITA_Fecha]
			,[BITA_Observacion]
		)
		SELECT 
			@DOCU_Codigo,
			DOCU.DOCU_ESTA_Codigo,
			@ENTI_Codigo,
			GETDATE(),
			@BITA_Observacion
		FROM
			TB_BPM_Documento DOCU
		WHERE
			DOCU_Codigo = @DOCU_Codigo;
		----------------------------------------------------------------------------------------

		IF(@PEND_Url IS NULL)
			BEGIN
				----------------------------------------------------------------------------------------
				 --- ELIMINA EL PENDIENTE YA QUE NO TIENE EMRPESA AL CUAL ASOCIARSE
				DELETE FROM TB_BPM_Tarea WHERE TARE_DOCU_Codigo	=	@DOCU_Codigo
				----------------------------------------------------------------------------------------	
			END
		ELSE
			BEGIN
				IF (@CONTADOR_TAREAS > 0)
					BEGIN
						DELETE FROM TB_BPM_Tarea
						WHERE
							TARE_DOCU_Codigo =	@DOCU_Codigo; 
					END
				
				-----------------------------------------------------------
				INSERT INTO TB_BPM_Tarea(
					  TARE_DOCU_Codigo,
					  TARE_ENTI_Codigo,
					  TARE_Url
				) 
				SELECT 
					@DOCU_Codigo,
					ENTI.ENTI_Codigo,
					@PEND_Url
				FROM
					@Destinatarios	ENTI	
				-----------------------------------------------------------
			END
		
		----------------------------------------------------------------------------------------
		--- ACTUALIZA EL DOCUMENTO 
		UPDATE TB_BPM_Documento 
		SET
		  DOCU_ESTA_Codigo	=	@ESTA_Codigo_Final
		WHERE
		  DOCU_Codigo		=	@DOCU_Codigo
		----------------------------------------------------------------------------------------

		
		----------------------------------------------------------------------------------------
		--- VERIFICA SI EXISTE ALGUN PROCEDIMIENTO AUXILIAR PARA EL CAMBIO DE ESTADO ACTUAL
		DECLARE @SP	VARCHAR(200);
		
		OPEN AUX_PROCEDIMIENTOS;
		FETCH AUX_PROCEDIMIENTOS INTO @SP;

		WHILE (@@FETCH_STATUS = 0)
			BEGIN	
				
				EXEC @SP @DOCU_Codigo, @ESTA_Codigo_Final
			
				FETCH AUX_PROCEDIMIENTOS INTO @SP;
			END 

		CLOSE AUX_PROCEDIMIENTOS;
		DEALLOCATE AUX_PROCEDIMIENTOS;
		----------------------------------------------------------------------------------------
		
		----------------------------------------------------------------------------------------
		--- NOTIFICACIONES
		DECLARE @PLANTILLA		VARCHAR(4000);
		DECLARE @TINO_Codigo	INT;
		
		OPEN AUX_NOTIFICACIONES;
		FETCH AUX_NOTIFICACIONES INTO @TINO_Codigo,@PLANTILLA;

		WHILE (@@FETCH_STATUS = 0)
			BEGIN	
				
				INSERT INTO TB_BPM_Notificacion
				(
					NOTI_DOCU_Codigo,
					NOTI_ENTI_Codigo,
					NOTI_Texto,
					NOTI_TINO_Codigo
				)
				SELECT 
					@DOCU_Codigo,
					ENTI.ENTI_Codigo,
					[dbo].[FN_BPM_INTERPOLAR](ENTI2.ENTI_Token,@DOCU_Token, @PLANTILLA),
					@TINO_Codigo
				FROM 
					@Destinatarios		ENTI,
					TB_MAE_Usuario		USUA,
					TB_MAE_Entidad		ENTI2
				WHERE
					ENTI2.ENTI_Codigo	=	ENTI.ENTI_Codigo	AND
					USUA.USUA_Codigo	=	ENTI.ENTI_Codigo
			
				FETCH AUX_NOTIFICACIONES INTO @TINO_Codigo, @PLANTILLA;
			END 

		CLOSE AUX_NOTIFICACIONES;
		DEALLOCATE AUX_NOTIFICACIONES;
		----------------------------------------------------------------------------------------

		-- SI @ListarDestinarios = 0 , NO SE DEVUELVE EL LISTADO DE ENTIDADES A NOTIFICAR
		IF(@ListarDestinatarios =1)
			BEGIN
				
				SELECT 
					[dbo].[FN_BPM_INTERPOLAR](@ENTI_Token, @DOCU_Token, CNOT.CNOT_Plantilla) as Notificacion,
					TIDO.TIDO_Nombre,
					ESTA.ESTA_Nombre,
					ENTI.ENTI_Identificador,
					UNOT.TINO_Codigo
				FROM
					TB_BPM_NotificacionTransicion		CNOT, 
					TB_BPM_Estado						ESTA,
					TB_BPM_TipoDocumento				TIDO,
					TB_BPM_Transicion					TRNE,
					TB_MAE_Entidad						ENTI,
					(SELECT 
						T1.ENTI_Codigo,
						T2.TINO_Codigo
					FROM
						@Destinatarios				T1,
						TB_BPM_TipoNotificacion	T2) AS UNOT
				WHERE
					UNOT.TINO_Codigo		= CNOT.CNOT_TINO_Codigo	AND
					UNOT.ENTI_Codigo		= ENTI.ENTI_Codigo		AND
					CNOT.CNOT_TRAN_Codigo	= TRNE.TRAN_Codigo		AND
					TRNE.TRAN_ESTA_Codigo	= ESTA.ESTA_Codigo		AND
					TIDO.TIDO_Codigo		= ESTA.ESTA_TIDO_Codigo	AND
					CNOT.CNOT_TRAN_Codigo	= @TRAN_Codigo			AND
					ENTI.ENTI_Codigo	IN (SELECT ENTI_Codigo FROM @Destinatarios)
			END

		COMMIT TRANSACTION @TRANNAME
				
		END TRY
		BEGIN CATCH
			--------------------------------------------------------
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION @TRANNAME
			--------------------------------------------------------
			
			DEALLOCATE AUX_PROCEDIMIENTOS;
			DEALLOCATE AUX_NOTIFICACIONES;

			--------------------------------------------------------
			--- LOG ERROR
			EXEC PA_MAE_INS_Error @ENTI_token=@ENTI_token
			--------------------------------------------------------
		END CATCH
END


















GO
/****** Object:  StoredProcedure [dbo].[PA_BPM_OBT_AccionesTransicion]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Obtiene las acciones disponibles 
--				para un documento de acuerdo a su estado.
-- =================================================================
CREATE PROCEDURE [dbo].[PA_BPM_OBT_AccionesTransicion] 
	@DOCU_Token			UNIQUEIDENTIFIER
AS
BEGIN	
	
	DECLARE @DOCU_Codigo			INT = dbo.FN_OBT_DOCU_Codigo(@DOCU_Token);	-- DOCUMENTO A PROCESAR

	SELECT
		TRNX.TRAN_Nombre,
		TRNX.TRAN_Token,
		TRNX.TRAN_Url
	FROM
		TB_BPM_Transicion	TRNX,
		TB_BPM_Documento	DOCU
	WHERE
		TRNX.TRAN_ESTA_Codigo	=		DOCU.DOCU_ESTA_Codigo	AND
		DOCU.DOCU_Codigo		=		@DOCU_Codigo

END


















GO
/****** Object:  StoredProcedure [dbo].[PA_BPM_OBT_Bitacora]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Obtiene el historial de cambios de estados
--				sobre un documento en particular.
-- =================================================================
CREATE PROCEDURE [dbo].[PA_BPM_OBT_Bitacora] 
	@DOCU_Token			UNIQUEIDENTIFIER
AS
BEGIN
	DECLARE @DOCU_Codigo	INT = dbo.FN_OBT_DOCU_Codigo(@DOCU_Token);

	-- HISTORIA
	SELECT 
		BITA.BITA_Fecha,
		BITA.BITA_Observacion,
		BITA.ENTI_Token,
		BITA.ENTI_Identificador,
		BITA.ESTA_Token,
		BITA.ESTA_Nombre,
		BITA.ESTA_Identificador,
		BITA.TIEN_Token,
		BITA.TIEN_Nombre,
		BITA.TIEN_Identificador
	FROM
		(SELECT 
			BITA.BITA_Fecha,
			BITA.BITA_Observacion,
			ENTI.ENTI_Token,
			ENTI.ENTI_Identificador,
			ESTA.ESTA_Token,
			ESTA.ESTA_Nombre,
			ESTA.ESTA_Identificador,
			TIEN.TIEN_Token,
			TIEN.TIEN_Nombre,
			TIEN.TIEN_Identificador
		FROM
			TB_BPM_Bitacora			BITA,
			TB_BPM_Documento		DOCU,
			TB_BPM_Estado			ESTA,
			TB_MAE_Entidad			ENTI,
			TB_MAE_TipoEntidad		TIEN
		WHERE
			ENTI.ENTI_TIEN_Codigo	=	TIEN.TIEN_Codigo		AND
			ENTI.ENTI_Codigo		=	BITA.BITA_ENTI_Codigo	AND
			BITA.BITA_DOCU_Codigo	=	DOCU.DOCU_Codigo		AND
			BITA.BITA_ESTA_Codigo	=	ESTA.ESTA_Codigo		AND
			DOCU.DOCU_Codigo		=	@DOCU_Codigo) BITA	
		ORDER BY
			BITA.BITA_Fecha DESC
END


















GO
/****** Object:  StoredProcedure [dbo].[PA_BPM_OBT_Documento]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Obtiene la informacion basica de un documento
--				en particular, presentando su estado actual
-- =================================================================
CREATE PROCEDURE [dbo].[PA_BPM_OBT_Documento] 
	@DOCU_Token			UNIQUEIDENTIFIER
AS
BEGIN	
	
	DECLARE @DOCU_Codigo			INT = dbo.FN_OBT_DOCU_Codigo(@DOCU_Token);	-- DOCUMENTO A PROCESAR

	-- DOCUMENT 
	SELECT
		DOCU.DOCU_Token,
		DOCU.DOCU_Identificador,
		DOCU.DOCU_Fecha,
		TIDO.TIDO_Token,
		TIDO.TIDO_Nombre,
		TIDO.TIDO_Identificador,
		ESTA.ESTA_Token,
		ESTA.ESTA_Nombre,
		ESTA.ESTA_Identificador,
		ENTI.ENTI_Token,
		ENTI.ENTI_Identificador,
		TIEN.TIEN_Token,
		TIEN.TIEN_Nombre,
		TIEN.TIEN_Identificador,
		(SELECT TOP 1 
			BITA_Observacion 
		FROM 
			TB_BPM_Bitacora BITA 
		WHERE 
			BITA.BITA_DOCU_Codigo = @DOCU_Codigo 
		ORDER BY
			BITA.BITA_Fecha DESC) as BITA_Observacion
	FROM
		TB_BPM_Documento		DOCU	INNER JOIN
		TB_BPM_TipoDocumento	TIDO	ON TIDO.TIDO_Codigo	=	DOCU.DOCU_TIDO_Codigo	INNER JOIN
		TB_BPM_Estado			ESTA	ON ESTA.ESTA_Codigo	=	DOCU.DOCU_ESTA_Codigo	INNER JOIN
		TB_MAE_Entidad			ENTI	ON ENTI.ENTI_Codigo	=	DOCU.DOCU_ENTI_Codigo	INNER JOIN
		TB_MAE_TipoEntidad		TIEN	ON TIEN.TIEN_Codigo	=	ENTI.ENTI_TIEN_Codigo
	WHERE
		DOCU.DOCU_Codigo	=	@DOCU_Codigo;


END


















GO
/****** Object:  StoredProcedure [dbo].[PA_BPM_OBT_Tareas]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Obtiene el listao de tareas pendientes del usuario o 
--				del perfil
-- =================================================================
CREATE PROCEDURE [dbo].[PA_BPM_OBT_Tareas] 
	@ENTI_Token			UNIQUEIDENTIFIER
AS
BEGIN	
	DECLARE @ENTI_Codigo INT	= dbo.FN_OBT_ENTI_Codigo(@ENTI_Token);

	-----------------------------------------------------------------
	-- TAREAS ESPECIFICAS DEL USUARIO
	SELECT 
		DOCU.DOCU_Token,
		TIDO.TIDO_Token,
		ESTA.ESTA_Token,
		DOCU.DOCU_Identificador,
		TIDO.TIDO_Nombre,
		ESTA.ESTA_Nombre,
		TARE.TARE_Fecha,
		TARE.TARE_Url
	FROM
		TB_BPM_Tarea			TARE INNER JOIN
		TB_BPM_Documento		DOCU ON DOCU.DOCU_Codigo	= TARE.TARE_DOCU_Codigo	INNER JOIN
		TB_BPM_Estado			ESTA ON ESTA.ESTA_Codigo	= DOCU.DOCU_ESTA_Codigo INNER JOIN
		TB_BPM_TipoDocumento	TIDO ON TIDO.TIDO_Codigo	= DOCU.DOCU_TIDO_Codigo
	WHERE
		TARE.TARE_ENTI_Codigo	= @ENTI_Codigo
	-----------------------------------------------------------------

	UNION ALL

	-----------------------------------------------------------------
	-- TAREAS ASOCIADAS A LOS ROLES DEL USUARIO
	SELECT 
		DOCU.DOCU_Token,
		TIDO.TIDO_Token,
		ESTA.ESTA_Token,
		DOCU.DOCU_Identificador,
		TIDO.TIDO_Nombre,
		ESTA.ESTA_Nombre,
		TARE.TARE_Fecha,
		TARE.TARE_Url
	FROM
		TB_BPM_Tarea			TARE INNER JOIN
		TB_BPM_Documento		DOCU ON DOCU.DOCU_Codigo		= TARE.TARE_DOCU_Codigo INNER JOIN
		TB_MAE_Perfil_Usuario	PEUS ON TARE.TARE_ENTI_Codigo	= PEUS.PUES_PERF_Codigo INNER JOIN
		TB_BPM_Estado			ESTA ON ESTA.ESTA_Codigo		= DOCU.DOCU_ESTA_Codigo INNER JOIN
		TB_BPM_TipoDocumento	TIDO ON TIDO.TIDO_Codigo		= DOCU.DOCU_TIDO_Codigo
	WHERE
		PEUS.PEUS_USUA_Codigo	= @ENTI_Codigo
	-----------------------------------------------------------------
		
END


















GO
/****** Object:  StoredProcedure [dbo].[PA_MAE_ACT_Archivo_QuitarMarcaTemporal]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Remueve la marca de "achivo temporal" sobre un 
--				archivo ingresado en la base de datos
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MAE_ACT_Archivo_QuitarMarcaTemporal]
	@ARCH_CODIGO				INT
AS	
BEGIN
	UPDATE TB_MAE_Archivo
	SET
		ARCH_Temporal = 0
	WHERE
		ARCH_CODIGO = @ARCH_CODIGO
END














GO
/****** Object:  StoredProcedure [dbo].[PA_MAE_ACT_Usuario]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Actualiza la información de un usuarios y sus 
--				perfiles asociados.
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MAE_ACT_Usuario]
	@USUA_Token				UNIQUEIDENTIFIER = NULL,
	@ENTI_Token				UNIQUEIDENTIFIER = NULL,	-- ENTIDAD QUE REALIZA PROCEDIMIENTO
	@ENTI_Nombre			VARCHAR(200),		
	@USUA_Email				VARCHAR(300),
	@ARCH_Token				UNIQUEIDENTIFIER = NULL,
	@PRF_Tokens				VARCHAR(8000),				-- TOKENS SEPARADOS POR COMA
	@USUA_Activo			BIT
AS	
BEGIN
	DECLARE     @TRANNAME		  VARCHAR(20) = 'TRANNAME';

	IF @PRF_Tokens = '' 
		BEGIN
			SET @PRF_Tokens = NULL;
		END

	BEGIN TRAN @TRANNAME
		BEGIN TRY
			DECLARE @USUA_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@USUA_Token);
			DECLARE @ARCH_Codigo	INT = dbo.FN_OBT_ARCH_Codigo(@ARCH_Token);

			------------------------------------------------------------------------
			UPDATE TB_MAE_Usuario
			SET
				USUA_Email			=	@USUA_Email,
				USUA_NombreCompleto	=	@ENTI_Nombre,
				USUA_Activo			=	@USUA_Activo
			WHERE
				USUA_Codigo			=	@USUA_Codigo;
			------------------------------------------------------------------------

	
			------------------------------------------------------------------------
			-- PASO 4: PERFILES DEL USUARIO
			DELETE FROM TB_MAE_Perfil_Usuario WHERE PEUS_USUA_Codigo	=	@USUA_Codigo;	--	LIMPIEZA DE ROLES 

			INSERT INTO TB_MAE_Perfil_Usuario
			SELECT
				@USUA_Codigo,
				PERF.PERF_Codigo
			FROM
				dbo.FN_MAE_SEPARAR(',',@PRF_Tokens)	T INNER JOIN
				TB_MAE_Entidad				ENTI	ON	T.s = ENTI.ENTI_Token	INNER JOIN
				TB_MAE_Perfil				PERF	ON	PERF.PERF_Codigo	=	ENTI.ENTI_Codigo
			------------------------------------------------------------------------

			--[ SI EXISTE UNA FOTO SUBIDA , SE VERIFICA QUE ESTE NO SEA EL MISMO QUE YA EXISTE PARA EL USUARIO
			IF(@ARCH_Codigo IS NOT NULL)
				BEGIN
					DECLARE @ARCH_CODIGO_ORIGINAL INT = (SELECT TOP 1 USUA.USUA_ARCH_Codigo FROM TB_MAE_Usuario USUA WHERE USUA.USUA_Codigo = @USUA_Codigo);

					------------------------------------------
					--[ SE REMUEVE LA MARCA DE TEMPORAL
					EXEC PA_MAE_ACT_Archivo_QuitarMarcaTemporal @ARCH_CODIGO
					------------------------------------------

					------------------------------------------
					--[ SE ACTUALIZA LA FOTO DEL USUARIO
					UPDATE TB_MAE_Usuario
					SET
						USUA_ARCH_Codigo	=	@ARCH_CODIGO
					WHERE
						USUA_Codigo			=	@USUA_Codigo
					------------------------------------------

					IF(@ARCH_CODIGO_ORIGINAL <> @ARCH_Codigo)
						BEGIN
							------------------------------------------------------------------------------------
							--[ SI LOS ARCHIVOS SON DISTINTAS , SE BORRA EL QUE ACTUALMENTE ESTABA
							DELETE FROM TB_MAE_Archivo
							WHERE
								ARCH_Codigo	=	@ARCH_CODIGO_ORIGINAL
							------------------------------------------------------------------------------------
						END					

				END

			
			COMMIT TRANSACTION @TRANNAME
		
		END TRY
		BEGIN CATCH
			--------------------------------------------------------
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION @TRANNAME
			--------------------------------------------------------
			
			--------------------------------------------------------
			--- LOG ERROR
			EXEC PA_MAE_INS_Error @ENTI_token = @ENTI_Token
			--------------------------------------------------------
		END CATCH
END














GO
/****** Object:  StoredProcedure [dbo].[PA_MAE_ELM_Usuario]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Desactiva un usuario en el sistema, (elimina su acceso).
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MAE_ELM_Usuario]
	@ENTI_Token		UNIQUEIDENTIFIER,
	@USUA_Token		UNIQUEIDENTIFIER
AS	
BEGIN
	UPDATE TB_MAE_Usuario
	SET
		USUA_Activo	= 0
	WHERE
		USUA_Codigo	= (	SELECT TOP 1 
							ENTI.ENTI_Codigo 
						FROM 
							TB_MAE_Entidad ENTI 
						WHERE 
							ENTI.ENTI_Token	=	@ENTI_Token);
END














GO
/****** Object:  StoredProcedure [dbo].[PA_MAE_INS_Archivo]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Inserta un archivo binario en el sistema
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MAE_INS_Archivo]
	@ARCH_Nombre			VARCHAR(60),
	@ARCH_Tamano			INT,
	@ARCH_ContentType		VARCHAR(100),
	@ARCH_Temporal			BIT = 0,	
	@ARCH_Binario			IMAGE,
	@ENTI_Token				UNIQUEIDENTIFIER
AS	
BEGIN
	DECLARE @TRANNAME	VARCHAR(20) = 'TRANNAME';
	
	BEGIN TRAN @TRANNAME
		BEGIN TRY
		----------------------------------------------------------------------
		-- [1: CREA EL ARCHIVO BASE]		
		INSERT INTO TB_MAE_Archivo
		(
			[ARCH_Nombre]
			,[ARCH_Tamano]
			,[ARCH_ContentType]
			,[ARCH_Temporal]
		) VALUES (
			@ARCH_Nombre,
			@ARCH_Tamano,
			@ARCH_ContentType,
			@ARCH_Temporal
		)
		
		DECLARE @ARCH_Codigo  INT = SCOPE_IDENTITY();
		
		-- [1: ASOCIA EL ARCHIVO BINARIO]		
		INSERT INTO TB_MAE_ArchivoBinario
		(
			ARCH_Codigo
			,[ARCH_Binario]
		)
		VALUES
		(
			@ARCH_Codigo,
			@ARCH_Binario
		)
			
		COMMIT TRANSACTION @TRANNAME
		
		----------------------------------------------------------------------
		SELECT 
			ARCH.ARCH_Token
		FROM
			TB_MAE_Archivo ARCH
		WHERE
			ARCH.ARCH_Codigo = @ARCH_Codigo
			
		----------------------------------------------------------------------
		END TRY
		BEGIN CATCH
			--------------------------------------------------------
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION @TRANNAME
			--------------------------------------------------------
			
			--------------------------------------------------------
			--- LOG ERROR
			EXEC PA_MAE_INS_Error @ENTI_token=@ENTI_Token
			--------------------------------------------------------
		END CATCH
END

















GO
/****** Object:  StoredProcedure [dbo].[PA_MAE_INS_Error]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Registra un error producido por la ejecución de 
--				algún script o sentencia SQL
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MAE_INS_Error] 
	 @ENTI_Token	UNIQUEIDENTIFIER,
	 @ELOG_Tipo		VARCHAR(200)	= NULL,
	 @ELOG_Pila		VARCHAR(8000)	= NULL
AS
BEGIN
    DECLARE @ENTI_Codigo	INT	= dbo.FN_OBT_ENTI_Codigo(@ENTI_Token);
	DECLARE @ERROR_MESSAGE	NVARCHAR(4000) = ERROR_MESSAGE();
	DECLARE @THROWEX		BIT = 0;

	--------------------------------------------------------
	IF(@ELOG_Pila IS NULL)	-- EXCEPCIÓN POR ALGUN PROCEDIMIENTO INTERNO (DB)
		BEGIN	
			SET @ELOG_Tipo = 'DBERROR';
			SET @ELOG_Pila = ERROR_PROCEDURE() + ': ' + @ERROR_MESSAGE;
			SET @THROWEX = 1;
		END
	--------------------------------------------------------
	INSERT INTO TB_MAE_LogError
    (
		[ELOG_ENTI_Codigo]
		,[ELOG_Tipo]
		,[ELOG_Pila]
    )
	VALUES 
	(
		@ENTI_Codigo,
		@ELOG_Tipo,
		@ELOG_Pila
	)
	--------------------------------------------------------
	IF(@THROWEX = 1) -- EXCEPCIÓN POR ALGUN PROCEDIMIENTO INTERNO (DB)
		BEGIN
			DECLARE @ERROR_SEVERITY INT = ERROR_SEVERITY();
			DECLARE @ERROR_STATE	INT = ERROR_STATE();

			RAISERROR (
				@ERROR_MESSAGE,		-- Message text.
				@ERROR_SEVERITY,	-- Severity.
				@ERROR_STATE		-- State.
			);
		END
	--------------------------------------------------------

	
END


GO
/****** Object:  StoredProcedure [dbo].[PA_MAE_INS_Usuario]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Actualiza la información particular de un usuario
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MAE_INS_Usuario]
	@ENTI_Token				UNIQUEIDENTIFIER = NULL,	-- ENTIDAD QUE REALIZA PROCEDIMIENTO
	@ENTI_Nombre			VARCHAR(200),		
	@ENTI_Identificador		VARCHAR(200),
	@ENTI_Email				VARCHAR(200),
	@ARCH_Token				UNIQUEIDENTIFIER = NULL,
	@USUA_Contrasena		VARCHAR(200),
	@PRF_Tokens				VARCHAR(8000) = NULL
AS	
BEGIN
	DECLARE     @TRANNAME		  VARCHAR(20) = 'TRANNAME';
	DECLARE		@TIEN_Codigo	  INT = (SELECT TOP 1 TIEN.TIEN_Codigo FROM TB_MAE_TipoEntidad TIEN WHERE TIEN.TIEN_Identificador = 'USUA');

	------------------------------------------------------------------------------------------------
	IF EXISTS(SELECT * FROM TB_MAE_Entidad ENTI WHERE UPPER(ENTI.ENTI_Identificador) = UPPER(@ENTI_Email))
		BEGIN
		
			----------------------
			-- RAISE CUSTOM ERROR (INSTEAD OF USE SQL SERVER -THROW- FEATURE)
			EXEC sp_addmessage  @msgnum = 50001, @severity = 16, @msgtext = N'USER_ALREADY_EXISTS';
			RAISERROR (50001, 16, 1);
			EXEC sp_dropmessage @msgnum = 50001;
			RETURN;
			----------------------

		END
	------------------------------------------------------------------------------------------------

	IF @PRF_Tokens = '' 
		BEGIN
			SET @PRF_Tokens = NULL;
		END

	BEGIN TRAN @TRANNAME
		BEGIN TRY
			DECLARE @ENTI_CODIGO	INT;
			DECLARE @ARCH_CODIGO	INT = dbo.FN_OBT_ARCH_Codigo(@ARCH_Token);

			------------------------------------------------------------------------
			-- PASO 1: SI EXISTE UN TOKEN DE ARCHIVO , SE ASOCIA LA FOTO AL USUARIO
			IF(@ARCH_CODIGO IS NOT NULL)
				BEGIN
					EXEC PA_MAE_ACT_Archivo_QuitarMarcaTemporal @ARCH_CODIGO
				END

			------------------------------------------------------------------------

			------------------------------------------------------------------------
			-- PASO 2: ENTIDAD
			INSERT INTO TB_MAE_Entidad
			(
				ENTI_TIEN_Codigo,				
				ENTI_Identificador
			)
			VALUES
			(
				@TIEN_Codigo,
				@ENTI_Identificador
			)
			SET @ENTI_CODIGO = SCOPE_IDENTITY();
			------------------------------------------------------------------------
		
			------------------------------------------------------------------------
			-- PASO 3: USUARIO
			INSERT INTO TB_MAE_USUARIO
			(
				USUA_Codigo,
				USUA_Contrasena,
				USUA_Activo,
				USUA_ARCH_Codigo,
				USUA_Email,
				USUA_NombreCompleto
			) VALUES (
				@ENTI_CODIGO,
				@USUA_Contrasena,	--> CLAVE TEMPORAL , HASTA QUE REVISE EL CORREO Y ACTIVE LA CUENTA
				0,					--> INACTIVO
				@ARCH_CODIGO,
				@ENTI_Email,
				@ENTI_Nombre
			)
			------------------------------------------------------------------------

			------------------------------------------------------------------------
			-- PASO 4: PERFILES DEL USUARIO
			INSERT INTO TB_MAE_Perfil_Usuario
			SELECT
				@ENTI_CODIGO,
				PERF.PERF_Codigo
			FROM
				dbo.FN_MAE_SEPARAR(',',@PRF_Tokens)	T INNER JOIN
				TB_MAE_Entidad				ENTI	ON	T.s = ENTI.ENTI_Token	INNER JOIN
				TB_MAE_Perfil				PERF	ON	PERF.PERF_Codigo	=	ENTI.ENTI_Codigo
			------------------------------------------------------------------------
			
			COMMIT TRANSACTION @TRANNAME

			------------------------------------------------------------------------
			SELECT 
				ENTI.ENTI_Token
			FROM 
				TB_MAE_Entidad	ENTI
			WHERE
				ENTI.ENTI_Codigo	=	@ENTI_CODIGO
			------------------------------------------------------------------------

		END TRY
		BEGIN CATCH
			--------------------------------------------------------
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION @TRANNAME
			--------------------------------------------------------
			
			--------------------------------------------------------
			--- LOG ERROR
			EXEC PA_MAE_INS_Error @ENTI_token = @ENTI_Token
			--------------------------------------------------------
		END CATCH
END
























GO
/****** Object:  StoredProcedure [dbo].[PA_MAE_OBT_ArchivoBinario]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Obtiene la información binario (Contenido) 
--				de un archivo
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MAE_OBT_ArchivoBinario]
	@ARCH_Token				UNIQUEIDENTIFIER
AS	
BEGIN
	----------------------------------------------------------------------
	SELECT 
		ARCH.ARCH_ContentType,
		ARCH.ARCH_Nombre,
		ARBI.ARCH_Binario
	FROM
		TB_MAE_Archivo ARCH,
		TB_MAE_ArchivoBinario ARBI
	WHERE
		ARCH.ARCH_Codigo = ARBI.ARCH_Codigo AND
		ARCH.ARCH_Token  = @ARCH_Token
	----------------------------------------------------------------------			
END

















GO
/****** Object:  StoredProcedure [dbo].[PA_MAE_OBT_AutenticarUsuario]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Valida que las credenciales del usuario sean 
--				validas, de ser asi , devuelve la información basica
--				de este y actualiza el registro de actividad.
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MAE_OBT_AutenticarUsuario] 
	@USUA_NombreUsuario			VARCHAR(200) = NULL,
	@USUA_Contrasena			VARCHAR(32) = NULL
AS
BEGIN
	DECLARE  @USUA_Codigo	INT = NULL;
	DECLARE  @USUA_Token	UNIQUEIDENTIFIER= NULL;
	SET NOCOUNT ON;

	--------------------------------------------------------------------------------
	SELECT 
		@USUA_Codigo = USUA_Codigo,
		@USUA_Token = ENTI.ENTI_Token
	FROM
		TB_MAE_Usuario	USUA,
		TB_MAE_Entidad	ENTI
	WHERE
		ENTI.ENTI_Codigo			=	USUA.USUA_Codigo					AND
		LOWER(ENTI.ENTI_Identificador)	=	LOWER(@USUA_NombreUsuario)		AND
		LOWER(USUA.USUA_Contrasena) =	LOWER(@USUA_Contrasena)				AND
		USUA_Activo	= 1;
	--------------------------------------------------------------------------------

	IF(@USUA_Codigo IS NOT NULL)
		BEGIN
			--------------------------------------------------------------------------------
			-- UPDATE LAST SESSION
			UPDATE TB_MAE_Usuario 
			SET
				USUA_UltimaConexion = GETDATE()
			WHERE
				USUA_Codigo = @USUA_Codigo;
			--------------------------------------------------------------------------------
			
			EXEC PA_MAE_OBT_InformacionUsuario @USUA_Token;
		END
END





























GO
/****** Object:  StoredProcedure [dbo].[PA_MAE_OBT_InformacionUsuario]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Obtiene la informacion del usuario objetivo , y el 
--				listado de perfiles asociados.
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MAE_OBT_InformacionUsuario] 
	@USUA_Token			UNIQUEIDENTIFIER
AS
BEGIN
	DECLARE  @USUA_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@USUA_Token);
	SET NOCOUNT ON;

	--------------------------------------------------------------------------------	
	-- OBTIENE LA INFORMACIÓN DEL USUARIO
	SELECT
		ENTI.ENTI_Token,
		ENTI.ENTI_Identificador,
		ENTI.ENTI_FechaCreacion,
		USUA.USUA_Email,
		USUA.USUA_UltimaConexion,
		USUA.USUA_NombreCompleto,
		ARCH.ARCH_Token
	FROM
		TB_MAE_Usuario	USUA INNER JOIN  
		TB_MAE_Entidad	ENTI ON ENTI.ENTI_Codigo	=	USUA.USUA_Codigo	AND 
		USUA.USUA_Codigo = @USUA_Codigo									 LEFT JOIN
		TB_MAE_Archivo	ARCH ON ARCH.ARCH_Codigo	=	USUA.USUA_ARCH_Codigo
	--------------------------------------------------------------------------------	
	-- OBTIENE LOS ROLES
	SELECT
		ENTI.ENTI_Identificador as ENTI_Nombre,
		ENTI.ENTI_Token,
		PERF.PERF_Identificador
	FROM
		TB_MAE_Perfil			PERF	INNER JOIN
		TB_MAE_Entidad			ENTI	ON ENTI.ENTI_Codigo			= PERF.PERF_Codigo INNER JOIN
		TB_MAE_Perfil_Usuario	PERFUSU ON PERFUSU.PUES_PERF_Codigo = PERF_Codigo AND 
		PERFUSU.PEUS_USUA_Codigo = @USUA_Codigo
	--------------------------------------------------------------------------------
END





























GO
/****** Object:  StoredProcedure [dbo].[PA_MOT_ELM_Ruta]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Elimina una ruta del sistema (se usa para hacer rollback , al existir un problema en la creacion)
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MOT_ELM_Ruta]
	@ENTI_Token		UNIQUEIDENTIFIER,
	@RUTA_Token		UNIQUEIDENTIFIER
AS	
BEGIN
	DECLARE @RUTA_Codigo INT = dbo.FN_MOT_OBT_RUTA_Codigo(@RUTA_Token);

	BEGIN TRY
		----------------------------------------
		-- CASCADE DELETIONS
		DELETE FROM TB_MOT_Coordenada 
		WHERE
			COOR_RUTA_Codigo = @RUTA_Codigo;

		DELETE FROM TB_MOT_Foto 
		WHERE
			FOTO_RUTA_Codigo = @RUTA_Codigo;

		DELETE FROM TB_MOT_RutaCompartida 
		WHERE
			RUCO_RUTA_Codigo = @RUTA_Codigo;

		DELETE FROM TB_MOT_Ruta 
		WHERE
			RUTA_Codigo = @RUTA_Codigo;
		----------------------------------------

	END TRY
	BEGIN CATCH
		--------------------------------------------------------
		--- LOG ERROR
		EXEC PA_MAE_INS_Error @ENTI_token=@ENTI_Token
		--------------------------------------------------------
	END CATCH

END














GO
/****** Object:  StoredProcedure [dbo].[PA_MOT_ELM_SeguimientoEmbajador]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Sigue un Emabajador
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MOT_ELM_SeguimientoEmbajador]
	@ENTI_Token			UNIQUEIDENTIFIER,	-- ENTIDAD QUE REALIZA PROCEDIMIENTO
	@USUA_Token			UNIQUEIDENTIFIER
	
AS	
BEGIN

	DECLARE @ENTI_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@ENTI_Token);
	DECLARE @USUA_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@USUA_Token);	-- EMBAJADOR
	
	BEGIN TRY
		IF EXISTS(SELECT * FROM TB_MOT_Siguiendo SIGI WHERE SIGI.SIGUI_USUA_Codigo_Siguiendo = @USUA_Codigo AND SIGI.SIGUI_USUA_Codigo = @ENTI_Codigo)
			BEGIN

				-- DESASOCIA EL EMBAJADOR AL USUARIO
				DELETE FROM [dbo].[TB_MOT_Siguiendo]
				WHERE
					SIGUI_USUA_Codigo = @ENTI_Codigo AND
					SIGUI_USUA_Codigo_Siguiendo = @USUA_Codigo;

				-- ACTUALIZA EL CONTADOR SOCIAL DEL USUARIO ACTUAL
				UPDATE TB_MOT_ContadorSocial
				SET
					SOCU_Siguiendo = (SOCU_Siguiendo -1)
				WHERE	
					SOCU_USUA_Codigo = @ENTI_Codigo;

				-- ACTUALIZA EL CONTADOR SOCIAL DEL EMABAJADOR
				UPDATE TB_MOT_ContadorSocial
				SET
					SOCU_Seguidores = (SOCU_Seguidores -1)
				WHERE	
					SOCU_USUA_Codigo = @USUA_Codigo;

			END

	END TRY
	BEGIN CATCH
		--------------------------------------------------------
		--- LOG ERROR
		EXEC PA_MAE_INS_Error @ENTI_token = @ENTI_Token
		--------------------------------------------------------
	END CATCH
END
























GO
/****** Object:  StoredProcedure [dbo].[PA_MOT_INS_CoordenadaRuta]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Asocia una coordenada a una ruta
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MOT_INS_CoordenadaRuta]
	@ENTI_Token			UNIQUEIDENTIFIER,	-- ENTIDAD QUE REALIZA PROCEDIMIENTO
	@RUTA_Token			UNIQUEIDENTIFIER,
	@COOR_Fecha			DATETIME,
	@COOR_Distancia		DECIMAL(18,5),
	@COOR_Velocidad		DECIMAL(18,5),
	@COOR_Latitud		DECIMAL(18,5),
	@COOR_Longitud		DECIMAL(18,5),
	@COOR_Altitud		DECIMAL(18,5),
	@COOR_Duracion		DECIMAL(18,5)
AS	
BEGIN

	DECLARE @ENTI_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@ENTI_Token);
	DECLARE @RUTA_Codigo	INT = dbo.FN_MOT_OBT_RUTA_Codigo(@RUTA_Token);
	
	BEGIN TRY

		INSERT INTO [dbo].[TB_MOT_Coordenada]
		(
			COOR_RUTA_Codigo,
			COOR_Altitud,
			COOR_Distancia,
			COOR_Fecha,
			COOR_Latitud,
			COOR_Longitud,
			COOR_Velocidad,
			COOR_Duracion
		) VALUES (
			@RUTA_Codigo,
			@COOR_Altitud,
			@COOR_Distancia,
			@COOR_Fecha,
			@COOR_Latitud,
			@COOR_Longitud,
			@COOR_Velocidad,
			@COOR_Duracion
		);

	END TRY
	BEGIN CATCH
		--------------------------------------------------------
		--- LOG ERROR
		EXEC PA_MAE_INS_Error @ENTI_token = @ENTI_Token
		--------------------------------------------------------
	END CATCH
END
























GO
/****** Object:  StoredProcedure [dbo].[PA_MOT_INS_Ruta]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Crea una ruta asociada al usuario (Sin Compartir)
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MOT_INS_Ruta]
	@ENTI_Token			UNIQUEIDENTIFIER = NULL,	-- ENTIDAD QUE REALIZA PROCEDIMIENTO

	@RUTA_Inicio		DATETIME,
	@RUTA_Fin			DATETIME,
	@RUTA_Duracion		INT,
	@RUTA_Pausas		INT,
	@RUTA_Distancia		DECIMAL(18,5),
	@RUTA_Velocidad		DECIMAL(18,5),
	@RUTA_Calorias		DECIMAL(18,5),
	@TISE_Identificador	CHAR(4),
	@RUTA_Latitud		DECIMAL(18,5),
	@RUTA_Longitud		DECIMAL(18,5),
	@RUTA_Altitud		DECIMAL(18,5),
	@RUTA_Imagen		VARCHAR(2048)

AS	
BEGIN
	DECLARE @ENTI_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@ENTI_Token);

	BEGIN TRY
			
		DECLARE @Ruta_Codigo	INT = NULL;
		DECLARE @TISE_Codigo	INT = (SELECT TOP 1 TISE.TISE_Codigo FROM TB_MOT_TipoSensacion TISE WHERE TISE.TISE_Identificador = @TISE_Identificador)

		INSERT INTO [dbo].[TB_MOT_Ruta]
		(
			[RUTA_USUA_Codigo]
			,[RUTA_Inicio]
			,[RUTA_Fin]
			,[RUTA_Duracion]
			,[RUTA_Pausas]
			,[RUTA_Distancia]
			,[RUTA_Velocidad]
			,[RUTA_Calorias]
			,[RUTA_TISE_Sensacion]
			,[RUTA_Latitud]
			,[RUTA_Longitud]
			,[RUTA_Altitud]
			,[RUTA_Imagen]
			,[RUTA_TIDE_Codigo]
		) VALUES (
			@ENTI_Codigo,
			@RUTA_Inicio,
			@RUTA_Fin,
			@RUTA_Duracion,
			@RUTA_Pausas,
			@RUTA_Distancia,
			@RUTA_Velocidad,
			@RUTA_Calorias,
			@TISE_Codigo,
			@RUTA_Latitud,
			@RUTA_Longitud,
			@RUTA_Altitud,
			@RUTA_Imagen,
			(SELECT TOP 1 USUA.USUA_TIDE_Codigo FROM TB_MAE_Usuario USUA WHERE USUA.USUA_Codigo = @ENTI_Codigo)
		);

		SET @Ruta_Codigo = SCOPE_IDENTITY();

		
		------------------------------------------------------------------------
		SELECT 
			RUTA.RUTA_token
		FROM 
			TB_MOT_Ruta	RUTA
		WHERE
			RUTA.RUTA_Codigo = @RUTA_Codigo
		------------------------------------------------------------------------

	END TRY
	BEGIN CATCH
		--------------------------------------------------------
		--- LOG ERROR
		EXEC PA_MAE_INS_Error @ENTI_token = @ENTI_Token
		--------------------------------------------------------
	END CATCH
END
























GO
/****** Object:  StoredProcedure [dbo].[PA_MOT_INS_SeguirEmbajador]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Sigue un Emabajador
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MOT_INS_SeguirEmbajador]
	@ENTI_Token			UNIQUEIDENTIFIER,	-- ENTIDAD QUE REALIZA PROCEDIMIENTO
	@USUA_Token			UNIQUEIDENTIFIER
	
AS	
BEGIN

	DECLARE @ENTI_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@ENTI_Token);
	DECLARE @USUA_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@USUA_Token);	-- EMBAJADOR
	
	BEGIN TRY
		IF NOT EXISTS(SELECT * FROM TB_MOT_Siguiendo SIGI WHERE SIGI.SIGUI_USUA_Codigo_Siguiendo = @USUA_Codigo AND SIGI.SIGUI_USUA_Codigo = @ENTI_Codigo)
			BEGIN

				-- ASOCIA EL EMBAJADOR AL USUARIO
				INSERT INTO [dbo].[TB_MOT_Siguiendo]
				(
					SIGUI_USUA_Codigo,
					SIGUI_USUA_Codigo_Siguiendo
				) VALUES (
					@ENTI_Codigo,
					@USUA_Codigo
				);

				-- ACTUALIZA EL CONTADOR SOCIAL DEL USUARIO ACTUAL
				UPDATE TB_MOT_ContadorSocial
				SET
					SOCU_Siguiendo = (SOCU_Siguiendo +1)
				WHERE	
					SOCU_USUA_Codigo = @ENTI_Codigo;

				-- ACTUALIZA EL CONTADOR SOCIAL DEL EMABAJADOR
				UPDATE TB_MOT_ContadorSocial
				SET
					SOCU_Seguidores = (SOCU_Seguidores +1)
				WHERE	
					SOCU_USUA_Codigo = @USUA_Codigo;

			END

	END TRY
	BEGIN CATCH
		--------------------------------------------------------
		--- LOG ERROR
		EXEC PA_MAE_INS_Error @ENTI_token = @ENTI_Token
		--------------------------------------------------------
	END CATCH
END
























GO
/****** Object:  StoredProcedure [dbo].[PA_MOT_OBT_AutenticarUsuarioExterno]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Obtiene un usuario via autenticador externo (si no existe crea al usuario)
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MOT_OBT_AutenticarUsuarioExterno]
	@USUA_NombreCompleto		VARCHAR(250),
	@USUA_Email					VARCHAR(100),		
	@AEXT_Identificador			VARCHAR(100),
	@ARCH_Binario				IMAGE = NULL,
	@ARCH_Tamano				INT = NULL,
	@TIAU_Identificador			CHAR(5)
AS	
BEGIN
	
	DECLARE @ENTI_Codigo	INT = (SELECT TOP 1 ENTI.ENTI_Codigo FROM TB_MAE_Entidad ENTI WHERE UPPER(ENTI.ENTI_Identificador) = UPPER(@USUA_Email));

	------------------------------------------------------------------------------------------------
	-- SI NO EXISTE UN USUARIO CON EMAIL , SE CREA UN USUARIO 
	-- YA QUE SE DEBE REGISTRAR SIEMPRE UN USUARIO PARA GENERAR EL TOKEN
	IF (@ENTI_Codigo IS NULL)
		BEGIN
			
			DECLARE     @TRANNAME		VARCHAR(20) = 'TRANNAME';
			DECLARE		@TIEN_Codigo	INT = (SELECT TOP 1 TIEN.TIEN_Codigo FROM TB_MAE_TipoEntidad TIEN WHERE TIEN.TIEN_Identificador = 'USUA');

			BEGIN TRAN @TRANNAME
			BEGIN TRY
				------------------------------------------------------------------------
				-- PASO 1: SE INSERTA LA FOTO DE PERFIL (DE EXISTIR)

				DECLARE @ARCH_Codigo  INT = NULL;
				IF(@ARCH_Binario IS NOT NULL)
					BEGIN
						INSERT INTO TB_MAE_Archivo
						(
							[ARCH_Nombre]
							,[ARCH_Tamano]
							,[ARCH_ContentType]
							,[ARCH_Temporal]
						) VALUES (
							'Profile Photo',
							@ARCH_Tamano,
							'image/png',
							0
						)
		
						SET @ARCH_Codigo = SCOPE_IDENTITY();
		
						INSERT INTO TB_MAE_ArchivoBinario
						(
							ARCH_Codigo
							,[ARCH_Binario]
						)
						VALUES
						(
							@ARCH_Codigo,
							@ARCH_Binario
						)

					END
				------------------------------------------------------------------------

				------------------------------------------------------------------------
				-- PASO 2: ENTIDAD
				INSERT INTO TB_MAE_Entidad
				(
					ENTI_TIEN_Codigo,				
					ENTI_Identificador
				)
				VALUES
				(
					@TIEN_Codigo,
					@USUA_Email
				)
				SET @ENTI_CODIGO = SCOPE_IDENTITY();
				------------------------------------------------------------------------
		
				------------------------------------------------------------------------
				-- PASO 3: USUARIO
				INSERT INTO TB_MAE_USUARIO
				(
					USUA_Codigo,
					USUA_Activo,
					USUA_ARCH_Codigo,
					USUA_Email,
					USUA_NombreCompleto
				) VALUES (
					@ENTI_CODIGO,
					1,
					@ARCH_CODIGO,
					@USUA_Email,
					@USUA_NombreCompleto
				)
				------------------------------------------------------------------------

				------------------------------------------------------------------------
				-- PASO 3: CONTADOR SOCIAL
				INSERT INTO TB_MOT_ContadorSocial
				(
					SOCU_USUA_Codigo,
					SOCU_MeGusta,
					SOCU_Seguidores,
					SOCU_Siguiendo
				) VALUES (
					@ENTI_CODIGO,
					0,
					0,
					0
				)
				------------------------------------------------------------------------

				------------------------------------------------------------------------
				-- PASO 4: ASOCIA EL AUTENTICADOR EXTERNO AL USUARIO CREADO
				INSERT INTO TB_MOT_AutenticadorExterno (
					AEXT_Identificador,
					AEXT_TIAU_Identificador,
					AEXT_USUA_Codigo 
				) VALUES (
					@AEXT_Identificador,
					@TIAU_Identificador,
					@ENTI_Codigo
				)
				------------------------------------------------------------------------
				

				COMMIT TRANSACTION @TRANNAME

			END TRY
			BEGIN CATCH
				--------------------------------------------------------
				IF @@TRANCOUNT > 0
					ROLLBACK TRANSACTION @TRANNAME
				--------------------------------------------------------
			
				----------------------
				-- RAISE CUSTOM ERROR (INSTEAD OF USE SQL SERVER -THROW- FEATURE)
				EXEC sp_addmessage  @msgnum = 50001, @severity = 16, @msgtext = N'EXTERNAL_USER_CREATING_ERROR';
				RAISERROR (50001, 16, 1);
				EXEC sp_dropmessage @msgnum = 50001;
				RETURN;
				----------------------
				
			END CATCH

		END
	------------------------------------------------------------------------------------------------

	-- GET TOKEN FROM THE USER
	DECLARE @ENTI_Token UNIQUEIDENTIFIER = (SELECT TOP 1 ENTI.ENTI_Token FROM TB_MAE_Entidad ENTI WHERE ENTI.ENTI_Codigo = @ENTI_Codigo)

	-- RETRIEVE THE USER INFORMATION
	EXEC [PA_MAE_OBT_InformacionUsuario] @ENTI_Token;
	
END
























GO
/****** Object:  StoredProcedure [dbo].[PA_MOT_OBT_Embajadores]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Obtiene el listado de embajadores de un usuario especifico
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MOT_OBT_Embajadores]
	@USUA_Token				UNIQUEIDENTIFIER
AS	
BEGIN
	DECLARE @USUA_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@USUA_Token); 
	DECLARE @EMBAJADORES TABLE (
		USUA_Codigo INT
	);

	----------------------------------------------------------------------
	INSERT INTO @EMBAJADORES
	SELECT 
		PEUS.PEUS_USUA_Codigo 
	FROM 
		TB_MAE_Perfil_Usuario PEUS 
	WHERE 
		PEUS.PEUS_USUA_Codigo NOT IN (@USUA_Codigo) AND
		PEUS.PUES_PERF_Codigo = 41;	--ROL DE EMBAJADOR

	----------------------------------------------------------------------
	SELECT
		ENTI.ENTI_Token,
		ENTI.ENTI_FechaCreacion,
		ENTI.ENTI_Identificador,
		ARCH.ARCH_Token,
		USUA.USUA_Codigo,
		USUA.USUA_Email,
		USUA.USUA_NombreCompleto,
		USUA.USUA_UltimaConexion,
		SOCU.SOCU_Seguidores,
		SOCU.SOCU_Siguiendo,
		SOCU.SOCU_MeGusta,
		TIDE.TIDE_Nombre,
		TIDE.TIDE_Descripcion,
		(SELECT COUNT(*) 
			FROM  TB_MOT_Siguiendo  SIGU 
			WHERE 
				SIGU.SIGUI_USUA_Codigo_Siguiendo = ENTI.ENTI_Codigo AND
				SIGU.SIGUI_USUA_Codigo = @USUA_Codigo)
		  as Siguiendo 
	FROM 
		TB_MAE_Entidad			ENTI	INNER JOIN
		@EMBAJADORES			EMBA	ON EMBA.USUA_Codigo			=	ENTI.ENTI_Codigo		INNER JOIN
		TB_MOT_ContadorSocial	SOCU	ON SOCU.SOCU_USUA_Codigo	=	ENTI.ENTI_Codigo		INNER JOIN
		TB_MAE_Usuario			USUA	ON USUA.USUA_Codigo			=	ENTI.ENTI_Codigo		INNER JOIN
		TB_MOT_TipoDeporte		TIDE	ON USUA.USUA_TIDE_Codigo	=	TIDE.TIDE_Codigo		LEFT JOIN
		TB_MAE_Archivo			ARCH	ON USUA.USUA_ARCH_Codigo	=	ARCH.ARCH_Codigo		AND
		USUA.USUA_Activo = 1;

	----------------------------------------------------------------------	

END

















GO
/****** Object:  StoredProcedure [dbo].[PA_MOT_OBT_Escritorio]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Obtiene información general del usuario segun el rango de tiempo establecido
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MOT_OBT_Escritorio]
	@USUA_Token				UNIQUEIDENTIFIER,
	@Rango					CHAR(1),
	@Fecha_Inicio			DATE,
	@Fecha_Fin				DATE
AS	
BEGIN
	DECLARE @USUA_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@USUA_Token); 

	----------------------------------------------------------------------
	SELECT 
		SUM(RUTA.RUTA_Calorias) as RUTA_Calorias,
		SUM(RUTA.RUTA_Distancia) as RUTA_Distancia,
		SUM(RUTA.RUTA_Velocidad) / COUNT(*) as RUTA_Velocidad
	FROM
		TB_MOT_Ruta RUTA
	WHERE
		RUTA.RUTA_Inicio BETWEEN @Fecha_Inicio AND @Fecha_Fin AND
		RUTA.RUTA_USUA_Codigo = @USUA_Codigo;
	----------------------------------------------------------------------	
	
	----------------------------------------------------------------------
	SELECT 
		SUM(RUTA.RUTA_Distancia) RUTA_Distancia,
		DATENAME(weekday, CONVERT(date,RUTA.RUTA_Inicio)) ,
		(CASE DATEPART(weekday, CONVERT(date,RUTA.RUTA_Inicio)) 
			WHEN 1 THEN 'L'
			WHEN 2 THEN 'M'
			WHEN 3 THEN 'm'
			WHEN 4 THEN 'J'
			WHEN 5 THEN 'V'
			WHEN 6 THEN 'S'
			WHEN 7 THEN 'D'
		END) as Etiqueta
	FROM
		TB_MOT_Ruta RUTA
	WHERE
		RUTA.RUTA_Inicio BETWEEN @Fecha_Inicio AND @Fecha_Fin AND
		RUTA.RUTA_USUA_Codigo = @USUA_Codigo
	GROUP BY 
		CONVERT(date,RUTA.RUTA_Inicio)
	----------------------------------------------------------------------		
END

















GO
/****** Object:  StoredProcedure [dbo].[PA_MOT_OBT_MisRutas]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Obtiene el listado de rutas de un usuario especifico
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MOT_OBT_MisRutas]
	@USUA_Token				UNIQUEIDENTIFIER,
	@MarcaTiempo			DATETIME
AS	
BEGIN
	DECLARE @USUA_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@USUA_Token); 

	----------------------------------------------------------------------
	SELECT
		RUTA.RUTA_Token,
		RUTA.RUTA_Fecha,
		RUTA.RUTA_Inicio,
		RUTA.RUTA_Fin,
		RUTA.RUTA_Altitud,
		RUTA.RUTA_Latitud,
		RUTA.RUTA_Longitud,
		RUTA.RUTA_Calorias,
		RUTA.RUTA_Distancia,
		RUTA.RUTA_Duracion,
		RUTA.RUTA_Pausas,
		RUTA.RUTA_Imagen,
		RUTA.RUTA_Velocidad,
		(CASE 
			WHEN RUCO.RUCO_RUTA_Codigo IS NULL THEN 0
			ELSE 1
		END) as Compartida,
		RUCO.RUCO_Nombre,
		RUCO.RUCO_MeGusta,
		RUCO.RUCO_Observaciones,
		RUCO.RUCO_Fecha,
		ENTI.ENTI_Token,
		ENTI.ENTI_Identificador,
		TISE.TISE_Nombre,
		TISE.TISE_Identificador,
		TISE.TISE_Token
	FROM
		TB_MAE_Entidad			ENTI	INNER JOIN
		TB_MOT_Ruta				RUTA	ON ENTI.ENTI_Codigo = RUTA.RUTA_USUA_Codigo	AND  RUTA.RUTA_Fecha >  @MarcaTiempo INNER JOIN
		TB_MOT_TipoSensacion	TISE	ON TISE.TISE_Codigo = RUTA.RUTA_TISE_Sensacion	LEFT JOIN
		TB_MOT_RutaCompartida	RUCO	ON RUTA.RUTA_Codigo	= RUCO.RUCO_RUTA_Codigo
	ORDER BY
		RUTA_Fecha DESC
	----------------------------------------------------------------------	

END

















GO
/****** Object:  StoredProcedure [dbo].[PA_MOT_OBT_Notificaciones]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Obtiene las notificacions de un usuario , de acuerdo al stamp especifico de tiempo
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MOT_OBT_Notificaciones]
	@USUA_Token				UNIQUEIDENTIFIER,
	@MarcaTiempo			DATETIME
AS	
BEGIN
	DECLARE @USUA_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@USUA_Token); 

	----------------------------------------------------------------------
	SELECT 
		NOTI.NOTI_Token,
		NOTI.NOTI_Texto,
		NOTI.NOTI_Fecha,
		NOTI.NOTI_Imagen,
		NOTI.NOTI_Contexto,
		TINO.TINO_Identificador,
		TINO.TINO_Nombre
	FROM 
		TB_MOT_Notificacion		NOTI	INNER JOIN
		TB_MOT_TipoNotificacion TINO	ON NOTI.NOTI_TINO_Identificador = TINO.TINO_Identificador
	WHERE
		NOTI.NOTI_Fecha >  @MarcaTiempo AND
		NOTI.NOTI_Leida = 0 AND
		NOTI.NOTI_USUA_Codigo = @USUA_Codigo
	----------------------------------------------------------------------		

END

















GO
/****** Object:  StoredProcedure [dbo].[PA_MOT_OBT_Perfl]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Obtiene la informacion del usuario objetivo , y el 
--				listado de perfiles asociados.
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MOT_OBT_Perfl] 
	@USUA_Token			UNIQUEIDENTIFIER
AS
BEGIN
	DECLARE  @USUA_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@USUA_Token);
	SET NOCOUNT ON;

	EXEC PA_MAE_OBT_InformacionUsuario @USUA_Token;

	--------------------------------------------------------
	-- CONTADORES TOTALES
	SELECT 
		(SELECT SUM(RUTA_Distancia) FROM TB_MOT_Ruta WHERE RUTA_USUA_Codigo = @USUA_Codigo) as RUTA_Distancia,
		SOCU.SOCU_MeGusta,
		SOCU.SOCU_Seguidores,
		SOCU.SOCU_Siguiendo
	FROM
		TB_MOT_ContadorSocial	SOCU
	WHERE
		SOCU.SOCU_USUA_Codigo	= @USUA_Codigo;
	--------------------------------------------------------

	--------------------------------------------------------
	-- DEPORTE ACTUAL
	SELECT
		TIDE.TIDE_Descripcion,
		TIDE.TIDE_Nombre
	FROM	
		TB_MOT_TipoDeporte	TIDE	INNER JOIN
		TB_MAE_Usuario		USUA	ON TIDE.TIDE_Codigo	= USUA.USUA_TIDE_Codigo
	WHERE
		USUA.USUA_Codigo = @USUA_Codigo;
	--------------------------------------------------------
	
	--------------------------------------------------------
	-- MEDALLAS
	--------------------------------------------------------
	
END





























GO
/****** Object:  StoredProcedure [dbo].[PA_MOT_OBT_Ruta]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Obtiene el listado de rutas de un usuario especifico
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MOT_OBT_Ruta]
	@USUA_Token				UNIQUEIDENTIFIER
AS	
BEGIN
	DECLARE @USUA_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@USUA_Token); 

	----------------------------------------------------------------------
	SELECT 
		*
	FROM
		TB_MOT_Ruta RUTA
	WHERE
		RUTA.RUTA_USUA_Codigo = @USUA_Codigo;
	----------------------------------------------------------------------	

END

















GO
/****** Object:  StoredProcedure [dbo].[PA_MOT_UPD_CompartirRuta]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Comparte una Ruta con el publico
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MOT_UPD_CompartirRuta]
	@ENTI_Token			UNIQUEIDENTIFIER,	-- ENTIDAD QUE REALIZA PROCEDIMIENTO
	@RUTA_Token			UNIQUEIDENTIFIER,

	@RUCO_Nombre		VARCHAR(200),
	@RUCO_Observaciones	VARCHAR(500) = NULL

AS	
BEGIN
	DECLARE @ENTI_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@ENTI_Token);
	DECLARE @RUTA_Codigo	INT = dbo.FN_MOT_OBT_RUTA_Codigo(@RUTA_Token);

	BEGIN TRY

		-- EXISTE RUTA?
		IF(@RUTA_Codigo IS NULL)
			BEGIN
				----------------------
				-- RAISE CUSTOM ERROR (INSTEAD OF USE SQL SERVER -THROW- FEATURE)
				EXEC sp_addmessage  @msgnum = 50001, @severity = 16, @msgtext = N'ROUTE_DONT_EXISTS';
				RAISERROR (50001, 16, 1);
				EXEC sp_dropmessage @msgnum = 50001;
				RETURN;
				----------------------
			END

		-- NO SE HA COMPARTIDO??	
		IF(EXISTS(SELECT * FROM TB_MOT_RutaCompartida RUCO WHERE RUCO.RUCO_RUTA_Codigo = @RUTA_Codigo))
			BEGIN
				----------------------
				-- RAISE CUSTOM ERROR (INSTEAD OF USE SQL SERVER -THROW- FEATURE)
				EXEC sp_addmessage  @msgnum = 50002, @severity = 16, @msgtext = N'ROUTE_ALREADY_SHARED';
				RAISERROR (50002, 16, 1);
				EXEC sp_dropmessage @msgnum = 50002;
				RETURN;
				----------------------
			END

		INSERT INTO [dbo].[TB_MOT_RutaCompartida]
		(
			RUCO_Fecha,
			RUCO_MeGusta,
			RUCO_Nombre,
			RUCO_Observaciones,
			RUCO_RUTA_Codigo
		) VALUES (
			GETDATE(),
			0,
			@RUCO_Nombre,
			@RUCO_Observaciones,
			@RUTA_Codigo
		);

	END TRY
	BEGIN CATCH
		--------------------------------------------------------
		--- LOG ERROR
		EXEC PA_MAE_INS_Error @ENTI_token = @ENTI_Token
		--------------------------------------------------------
	END CATCH
END
























GO
/****** Object:  StoredProcedure [dbo].[PA_MOT_UPD_MarcarNotificacionesComoLeidas]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Marca las notificaciones del usuario como leidas , segun la marca de tiempo 
-- =================================================================
CREATE PROCEDURE [dbo].[PA_MOT_UPD_MarcarNotificacionesComoLeidas]
	@USUA_Token				UNIQUEIDENTIFIER,
	@MarcaTiempo			DATETIME
AS	
BEGIN
	DECLARE @USUA_Codigo	INT = dbo.FN_OBT_ENTI_Codigo(@USUA_Token); 

	----------------------------------------------------------------------
	-- Actualiza todas las notificaciones a leidas
	UPDATE TB_MOT_Notificacion
	SET
		NOTI_Leida = 1
	WHERE
		NOTI_Fecha <= @MarcaTiempo AND
		NOTI_Leida = 0 AND
		NOTI_USUA_Codigo = @USUA_Codigo
	----------------------------------------------------------------------	
END

















GO
/****** Object:  UserDefinedFunction [dbo].[FN_BPM_Diccionario_Plantilla]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Devuelve el listado (nombre , valor) de las variables
--				a interpolar en las plantillas registradas en el sistema.
-- Note:		Las plantillas son usadas por las notificaciones y 
--				correos enviados al ejecutar una transición sobre un 
--				documento.
-- =================================================================
CREATE FUNCTION [dbo].[FN_BPM_Diccionario_Plantilla] (
	@USUA_Token	UNIQUEIDENTIFIER,
	@DOCU_Token	UNIQUEIDENTIFIER
)
RETURNS @RESULT_SET TABLE (
	NAME	VARCHAR(50),
	VALUE	VARCHAR(200)
) 
AS
BEGIN
	DECLARE @SEPARATOR_CHAR VARCHAR(20) = ','
	DECLARE @STRING_IDENTIFIER VARCHAR(20) = '\"'
	
	-- =============================================
	DECLARE @TIDO_CODIGO	INT	= (SELECT TOP 1 
										DOCU.DOCU_TIDO_Codigo 
									FROM 
										TB_BPM_Documento	DOCU 
									WHERE 
										DOCU.DOCU_Token	=	@DOCU_Token);

	-- =============================================
	-- KEYWORD		: ME_TOKEN
	-- DESCRIPTION	: RETORNA EL TOKEN DE USUARIO 
	INSERT INTO @RESULT_SET
	VALUES	(
		--	NAME
		'ME_TOKEN',		
		--	VALUE
		@USUA_Token		
	)
	-- =============================================


	-- =============================================
	-- KEYWORD		: ME
	-- DESCRIPTION	: RETORNA EL NOMBRE DE USUARIO 
	INSERT INTO @RESULT_SET
	VALUES	(
		--	NAME
		'ME',		
		--	VALUE
		(SELECT TOP 1 
			USUA.USUA_Email 
		FROM	
			TB_MAE_Usuario	USUA INNER JOIN 
			TB_MAE_Entidad	ENTI ON USUA.USUA_Codigo	 = ENTI.ENTI_Codigo
		WHERE 
			ENTI.ENTI_Token	=	@USUA_Token)			
	)
	-- =============================================
	
	RETURN
END

















GO
/****** Object:  UserDefinedFunction [dbo].[FN_BPM_INTERPOLAR]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		Valentys Ltda. (Gale Starter Project)
-- Create date: 2015.07.06
-- Description:	Interpola una plantilla , transformando las variables 
--				registradas en la plantilla bajo el formato definido
--				y reemplazandolas con el valor dinamico.
-- =================================================================
CREATE FUNCTION [dbo].[FN_BPM_INTERPOLAR]
(
	@USUA_token	UNIQUEIDENTIFIER,
	@DOCU_Token	UNIQUEIDENTIFIER= NULL,	
	@TEXT		VARCHAR(8000)
)
RETURNS VARCHAR(8000)
AS
BEGIN
	DECLARE @PREFIX VARCHAR(20) = 'FWK:(';
	DECLARE @SUFFIX VARCHAR(20) = ')'
	
	DECLARE KEYWORD_CURSOR CURSOR FOR SELECT NAME , VALUE FROM FN_BPM_DICCIONARIO_PLANTILLA(@USUA_token,@DOCU_Token);
	
	IF(CHARINDEX(@PREFIX, @TEXT) >0 )
		BEGIN
			----------------------------------------------------------------------------
			DECLARE @KEYWORD_NAME	VARCHAR(50);
			DECLARE @KEYWORD_VALUE	VARCHAR(200);
			
			OPEN KEYWORD_CURSOR
			FETCH NEXT FROM KEYWORD_CURSOR INTO @KEYWORD_NAME,@KEYWORD_VALUE;
				
			WHILE @@FETCH_STATUS = 0   
			BEGIN   
				SET @KEYWORD_NAME = @PREFIX + @KEYWORD_NAME + @SUFFIX;
				
				SET @TEXT = REPLACE(@TEXT, @KEYWORD_NAME, @KEYWORD_VALUE);
				
				FETCH NEXT FROM KEYWORD_CURSOR INTO @KEYWORD_NAME,@KEYWORD_VALUE;
			END 
					
			CLOSE KEYWORD_CURSOR
			DEALLOCATE KEYWORD_CURSOR
			----------------------------------------------------------------------------
		END
		
	RETURN @TEXT;

END

















GO
/****** Object:  UserDefinedFunction [dbo].[FN_BPM_OBT_DestinatariosTarea]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Obtiene el usuario destino de la tarea pendiente 
--				(de existir) para la transición actual ejecutada
--				sobre un documento.
-- =================================================================
CREATE FUNCTION [dbo].[FN_BPM_OBT_DestinatariosTarea]
(
	@DOCU_Codigo		INT,
	@ENTI_Codigo		INT
)
RETURNS @RESULT_SET TABLE (
	ENTI_Codigo	INT
) 
AS
BEGIN

	-- ENTIDAD DE ACCION
	INSERT @RESULT_SET
	(
		ENTI_Codigo
	) VALUES (
		@ENTI_Codigo
	);
		
	RETURN 
END

















GO
/****** Object:  UserDefinedFunction [dbo].[FN_MOT_OBT_RUTA_Codigo]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		Valentys Ltda.
-- Create date: 2015.07.06
-- Description:	Obtiene el codigo de la ruta de acuerdo al
--				token (GUID)
-- =================================================================
CREATE FUNCTION [dbo].[FN_MOT_OBT_RUTA_Codigo]
(
	@RUTA_Token	UNIQUEIDENTIFIER
)
RETURNS INT
AS
BEGIN
	DECLARE @RUTA_Codigo INT;
	
	SELECT
		@RUTA_Codigo = RUTA_Codigo 
	FROM
		TB_MOT_Ruta	RUTA
	WHERE
		RUTA.RUTA_token = @RUTA_Token;
		
		
	RETURN @RUTA_Codigo;
END

















GO
/****** Object:  UserDefinedFunction [dbo].[FN_OBT_ARCH_Codigo]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		Valentys Ltda. (Gale Starter Project)
-- Create date: 2015.07.06
-- Description:	Obtiene el codigo del archivo de acuerdo al
--				token (GUID)
-- =================================================================
CREATE FUNCTION [dbo].[FN_OBT_ARCH_Codigo]
(
	@ARCH_Token	UNIQUEIDENTIFIER
)
RETURNS INT
AS
BEGIN
	DECLARE @ARCH_Codigo INT;
	
	SELECT
		@ARCH_Codigo = ARCH_Codigo 
	FROM
		TB_MAE_Archivo	ARCH
	WHERE
		ARCH.ARCH_Token = @ARCH_Token;
		
		
	RETURN @ARCH_Codigo
END

















GO
/****** Object:  UserDefinedFunction [dbo].[FN_OBT_DOCU_Codigo]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		Valentys Ltda. (Gale Starter Project)
-- Create date: 2015.07.06
-- Description:	Obtiene el codigo del documento de acuerdo al
--				token (GUID)
-- =================================================================
CREATE FUNCTION [dbo].[FN_OBT_DOCU_Codigo]
(
	@DOCU_Token	UNIQUEIDENTIFIER
)
RETURNS INT
AS
BEGIN
	DECLARE @DOCU_Codigo INT;
	
	SELECT
		@DOCU_Codigo = DOCU_Codigo 
	FROM
		TB_BPM_Documento	DOCU
	WHERE
		DOCU.DOCU_Token = @DOCU_Token;
		
		
	RETURN @DOCU_Codigo
END

















GO
/****** Object:  UserDefinedFunction [dbo].[FN_OBT_ENTI_Codigo]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		Valentys Ltda. (Gale Starter Project)
-- Create date: 2015.07.06
-- Description:	Obtiene el codigo de la entidad de acuerdo al
--				token (GUID)
-- =================================================================
CREATE FUNCTION [dbo].[FN_OBT_ENTI_Codigo]
(
	@ENTI_Token	UNIQUEIDENTIFIER
)
RETURNS INT
AS
BEGIN
	DECLARE @ENTI_Codigo INT;
	
	SELECT
		@ENTI_Codigo = ENTI.ENTI_Codigo 
	FROM
		TB_MAE_Entidad	ENTI
	WHERE
		ENTI.ENTI_Token = @ENTI_Token;
		
		
	RETURN @ENTI_Codigo
END

















GO
/****** Object:  UserDefinedFunction [dbo].[FN_OBT_ESTA_Codigo]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		Valentys Ltda. (Gale Starter Project)
-- Create date: 2015.07.06
-- Description:	Obtiene el codigo del estado de acuerdo al
--				token (GUID)
-- =================================================================
CREATE FUNCTION [dbo].[FN_OBT_ESTA_Codigo]
(
	@ESTA_Token	UNIQUEIDENTIFIER
)
RETURNS INT
AS
BEGIN
	DECLARE @ESTA_Codigo INT;
	
	SELECT
		@ESTA_Codigo = ESTA.ESTA_Codigo 
	FROM
		TB_BPM_Estado	ESTA
	WHERE
		ESTA.ESTA_Token = @ESTA_Token;
		
		
	RETURN @ESTA_Codigo
END

















GO
/****** Object:  UserDefinedFunction [dbo].[FN_OBT_PERF_Codigo]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		Valentys Ltda. (Gale Starter Project)
-- Create date: 2015.07.06
-- Description:	Obtiene el codigo del perfil de acuerdo al
--				token (GUID)
-- =================================================================
CREATE FUNCTION [dbo].[FN_OBT_PERF_Codigo]
(
	@ENTI_Token	UNIQUEIDENTIFIER
)
RETURNS INT
AS
BEGIN
	DECLARE @PERF_Codigo INT;
	
	SELECT
		@PERF_Codigo = PERF_Codigo 
	FROM
		TB_MAE_Perfil	PERF,
		TB_MAE_Entidad	ENTI	
	WHERE
		ENTI.ENTI_Codigo	=	PERF.PERF_Codigo	AND
		ENTI.ENTI_Token		=	@ENTI_Token;
		
		
	RETURN @PERF_Codigo
END

















GO
/****** Object:  UserDefinedFunction [dbo].[FN_OBT_TIDO_Codigo]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		Valentys Ltda. (Gale Starter Project)
-- Create date: 2015.07.06
-- Description:	Obtiene el codigo del tipo de documento de acuerdo al
--				token (GUID)
-- =================================================================
CREATE FUNCTION [dbo].[FN_OBT_TIDO_Codigo]
(
	@TIDO_Token	UNIQUEIDENTIFIER
)
RETURNS INT
AS
BEGIN
	DECLARE @TIDO_Codigo INT;
	
	SELECT
		@TIDO_Codigo = TIDO_Codigo 
	FROM
		TB_BPM_TipoDocumento	TIDO
	WHERE
		TIDO.TIDO_Token = @TIDO_Token;
		
		
	RETURN @TIDO_Codigo
END

















GO
/****** Object:  UserDefinedFunction [dbo].[FN_OBT_TIEN_Codigo]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		Valentys Ltda. (Gale Starter Project)
-- Create date: 2015.07.06
-- Description:	Obtiene el codigo del tipo de entidad de acuerdo al
--				token (GUID)
-- =================================================================
CREATE FUNCTION [dbo].[FN_OBT_TIEN_Codigo]
(
	@TIEN_Token	UNIQUEIDENTIFIER
)
RETURNS INT
AS
BEGIN
	DECLARE @TIEN_Codigo INT;
	
	SELECT
		@TIEN_Codigo = TIEN_Codigo 
	FROM
		TB_MAE_TipoEntidad	TIEN
	WHERE
		TIEN.TIEN_Token = @TIEN_Token;
		
		
	RETURN @TIEN_Codigo
END

















GO
/****** Object:  UserDefinedFunction [dbo].[FN_OBT_TINO_Codigo]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		Valentys Ltda. (Gale Starter Project)
-- Create date: 2015.07.06
-- Description:	Obtiene el codigo del tipo de notificacion de
--				acuerdo al token (GUID)
-- =================================================================
CREATE FUNCTION [dbo].[FN_OBT_TINO_Codigo]
(
	@TINO_Token	UNIQUEIDENTIFIER
)
RETURNS INT
AS
BEGIN
	DECLARE @TINO_Codigo INT;
	
	SELECT
		@TINO_Codigo = TINO_Codigo 
	FROM
		TB_BPM_TipoNotificacion	TINO
	WHERE
		TINO.TINO_Token = @TINO_Token;
		
		
	RETURN @TINO_Codigo
END

















GO
/****** Object:  UserDefinedFunction [dbo].[FN_OBT_USUA_Codigo]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		Valentys Ltda. (Gale Starter Project)
-- Create date: 2015.07.06
-- Description:	Obtiene el codigo del usuario de acuerdo al
--				token (GUID)
-- =================================================================
CREATE FUNCTION [dbo].[FN_OBT_USUA_Codigo]
(
	@ENTI_Token	UNIQUEIDENTIFIER
)
RETURNS INT
AS
BEGIN
	DECLARE @USUA_Codigo INT;
	
	SELECT
		@USUA_Codigo = USUA_Codigo 
	FROM
		TB_MAE_Usuario	USUA,
		TB_MAE_Entidad	ENTI	
	WHERE
		ENTI.ENTI_Codigo	=	USUA.USUA_Codigo	AND
		ENTI.ENTI_Token		=	@ENTI_Token;
		
		
	RETURN @USUA_Codigo
END

















GO
/****** Object:  Table [dbo].[TB_BPM_Bitacora]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_BPM_Bitacora](
	[BITA_Codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BITA_ESTA_Codigo] [int] NOT NULL,
	[BITA_DOCU_Codigo] [int] NOT NULL,
	[BITA_ENTI_Codigo] [int] NOT NULL,
	[BITA_Fecha] [datetime] NOT NULL,
	[BITA_Observacion] [text] NULL,
 CONSTRAINT [PK_BPM_Bitacora] PRIMARY KEY CLUSTERED 
(
	[BITA_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TB_BPM_Documento]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_BPM_Documento](
	[DOCU_Codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[DOCU_ESTA_Codigo] [int] NOT NULL,
	[DOCU_TIDO_Codigo] [int] NOT NULL,
	[DOCU_ENTI_Codigo] [int] NOT NULL,
	[DOCU_Identificador] [char](9) NOT NULL,
	[DOCU_Fecha] [datetime] NOT NULL,
	[DOCU_Token] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_BPM_Documento] PRIMARY KEY CLUSTERED 
(
	[DOCU_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_BPM_Estado]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_BPM_Estado](
	[ESTA_Codigo] [int] NOT NULL,
	[ESTA_TIDO_Codigo] [int] NOT NULL,
	[ESTA_Nombre] [varchar](200) NOT NULL,
	[ESTA_Token] [uniqueidentifier] NOT NULL CONSTRAINT [DF__TB_BPM_Es__ESTA___1CF15040]  DEFAULT (newid()),
	[ESTA_Descripcion] [varchar](500) NOT NULL,
	[ESTA_Identificador] [char](4) NOT NULL,
 CONSTRAINT [PK_BPM_Estado] PRIMARY KEY CLUSTERED 
(
	[ESTA_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_BPM_Notificacion]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_BPM_Notificacion](
	[NOTI_Codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[NOTI_DOCU_Codigo] [int] NOT NULL,
	[NOTI_TINO_Codigo] [int] NOT NULL,
	[NOTI_ENTI_Codigo] [int] NOT NULL,
	[NOTI_Texto] [text] NOT NULL,
	[NOTI_Fecha] [datetime] NOT NULL,
	[NOTI_Token] [uniqueidentifier] NOT NULL,
	[NOTI_Leida] [bit] NOT NULL,
 CONSTRAINT [PK_BPM_Notificaciones] PRIMARY KEY CLUSTERED 
(
	[NOTI_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TB_BPM_NotificacionTransicion]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_BPM_NotificacionTransicion](
	[CNOT_Codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[CNOT_TINO_Codigo] [int] NOT NULL,
	[CNOT_TRAN_Codigo] [int] NOT NULL,
	[CNOT_Plantilla] [text] NOT NULL,
 CONSTRAINT [PK_BPM_ConfiguracionNotificaciones] PRIMARY KEY CLUSTERED 
(
	[CNOT_TINO_Codigo] ASC,
	[CNOT_TRAN_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TB_BPM_Tarea]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_BPM_Tarea](
	[TARE_Codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[TARE_DOCU_Codigo] [int] NOT NULL,
	[TARE_ENTI_Codigo] [int] NOT NULL,
	[TARE_Fecha] [datetime] NOT NULL,
	[TARE_Url] [varchar](2000) NULL,
 CONSTRAINT [PK_BPM_Pendientes] PRIMARY KEY CLUSTERED 
(
	[TARE_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_BPM_TipoDocumento]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_BPM_TipoDocumento](
	[TIDO_Codigo] [int] NOT NULL,
	[TIDO_Nombre] [varchar](200) NOT NULL,
	[TIDO_Descripcion] [varchar](500) NOT NULL,
	[TIDO_Identificador] [char](4) NOT NULL,
	[TIDO_Token] [uniqueidentifier] NOT NULL CONSTRAINT [DF__TB_BPM_Ti__TIDO___2B3F6F97]  DEFAULT (newid()),
 CONSTRAINT [PK_BPM_TipoDocumento] PRIMARY KEY CLUSTERED 
(
	[TIDO_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_BPM_TipoNotificacion]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_BPM_TipoNotificacion](
	[TINO_Codigo] [int] NOT NULL,
	[TINO_Identificador] [char](4) NOT NULL,
	[TINO_Nombre] [varchar](50) NOT NULL,
	[TINO_Token] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_BPM_TipoNotificacion] PRIMARY KEY CLUSTERED 
(
	[TINO_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_BPM_Transicion]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_BPM_Transicion](
	[TRAN_Codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[TRAN_ESTA_Codigo] [int] NOT NULL,
	[TRAN_ESTA_Codigo_Final] [int] NOT NULL,
	[TRAN_TIDO_Codigo] [int] NOT NULL,
	[ENTI_Codigo] [int] NULL,
	[TRAN_Nombre] [varchar](80) NOT NULL,
	[TRAN_Url] [varchar](2000) NULL,
	[TRAN_Identificador] [char](4) NOT NULL,
	[TRAN_Token] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_BPM_Transicion] PRIMARY KEY CLUSTERED 
(
	[TRAN_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_BPM_TransicionAuxiliar]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_BPM_TransicionAuxiliar](
	[CTRN_Codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[CTRN_TRAN_Codigo] [int] NOT NULL,
	[CTRN_Procedimiento] [varchar](200) NOT NULL,
 CONSTRAINT [PK_BPM_ConfiguracionTransicion] PRIMARY KEY CLUSTERED 
(
	[CTRN_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MAE_Archivo]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MAE_Archivo](
	[ARCH_Codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[ARCH_Nombre] [varchar](100) NOT NULL,
	[ARCH_Tamano] [int] NOT NULL,
	[ARCH_FechaCreacion] [datetime] NOT NULL CONSTRAINT [DF__TB_MAE_Ar__ARCH___2DE6D218]  DEFAULT (getdate()),
	[ARCH_ContentType] [varchar](100) NOT NULL,
	[ARCH_Temporal] [bit] NOT NULL CONSTRAINT [DF__TB_MAE_Ar__ARCH___2EDAF651]  DEFAULT ((0)),
	[ARCH_Token] [uniqueidentifier] NOT NULL CONSTRAINT [DF__TB_MAE_Ar__ARCH___2FCF1A8A]  DEFAULT (newid()),
 CONSTRAINT [PK_TB_File] PRIMARY KEY CLUSTERED 
(
	[ARCH_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MAE_ArchivoBinario]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MAE_ArchivoBinario](
	[ARCH_Codigo] [int] NOT NULL,
	[ARCH_Binario] [image] NOT NULL,
 CONSTRAINT [PK_TB_FileData] PRIMARY KEY CLUSTERED 
(
	[ARCH_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TB_MAE_AutenticadorInterno]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MAE_AutenticadorInterno](
	[USUA_Codigo] [int] NOT NULL,
	[USUA_Identificador] [varchar](100) NOT NULL,
	[USUA_Contrasena] [varchar](32) NOT NULL,
 CONSTRAINT [PK_TB_MAE_AutenticadorInterno] PRIMARY KEY CLUSTERED 
(
	[USUA_Identificador] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MAE_CategoriaMenu]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MAE_CategoriaMenu](
	[MCAT_Codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[MCAT_Nombre] [varchar](50) NULL,
	[MCAT_Token] [uniqueidentifier] NULL DEFAULT (newid()),
 CONSTRAINT [TB_MAE_CategoriaMenu_PK] PRIMARY KEY CLUSTERED 
(
	[MCAT_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MAE_Entidad]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MAE_Entidad](
	[ENTI_Codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[ENTI_TIEN_Codigo] [int] NOT NULL,
	[ENTI_Token] [uniqueidentifier] NOT NULL CONSTRAINT [DF__TB_MAE_En__ENTI___31B762FC]  DEFAULT (newid()),
	[ENTI_FechaCreacion] [datetime] NOT NULL CONSTRAINT [DF__TB_MAE_En__ENTI___32AB8735]  DEFAULT (getdate()),
	[ENTI_Identificador] [varchar](200) NOT NULL,
 CONSTRAINT [PK_BPM_Entidad] PRIMARY KEY CLUSTERED 
(
	[ENTI_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MAE_ItemMenu]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[TB_MAE_ItemMenu](
	[MITE_Codigo] [int] IDENTITY(1,1) NOT NULL,
	[MITE_MCAT_Codigo] [int] NOT NULL,
	[MITE_Nombre] [varchar](50) NOT NULL,
	[MITE_Url] [varchar](100) NOT NULL,
	[MITE_Icono] [varchar](100) NOT NULL,
	[MITE_Ordinal] [int] NULL,
 CONSTRAINT [PK_TB_MAE_MenuItem] PRIMARY KEY CLUSTERED 
(
	[MITE_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MAE_ItemMenu_Perfil]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MAE_ItemMenu_Perfil](
	[MENUPERF_PERF_Codigo] [int] NOT NULL,
	[MENUPERF_MITE_Codigo] [int] NOT NULL,
 CONSTRAINT [PK_TB_MAE_MenuItem_Perfil] PRIMARY KEY CLUSTERED 
(
	[MENUPERF_PERF_Codigo] ASC,
	[MENUPERF_MITE_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TB_MAE_LogError]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MAE_LogError](
	[ELOG_Codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[ELOG_ENTI_Codigo] [int] NOT NULL,
	[ELOG_Tipo] [varchar](200) NOT NULL,
	[ELOG_Pila] [varchar](4000) NOT NULL,
	[ELOG_Fecha] [datetime] NOT NULL CONSTRAINT [DF__TB_MAE_Lo__ELOG___3493CFA7]  DEFAULT (getdate()),
 CONSTRAINT [PK_TB_ErrorLogDB] PRIMARY KEY CLUSTERED 
(
	[ELOG_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MAE_Perfil]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MAE_Perfil](
	[PERF_Codigo] [int] NOT NULL,
	[PERF_Descripcion] [varchar](500) NOT NULL,
	[PERF_Identificador] [char](4) NOT NULL,
 CONSTRAINT [PK_TB_MAE_Perfil] PRIMARY KEY CLUSTERED 
(
	[PERF_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MAE_Perfil_Usuario]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MAE_Perfil_Usuario](
	[PEUS_USUA_Codigo] [int] NOT NULL,
	[PUES_PERF_Codigo] [int] NOT NULL,
 CONSTRAINT [PK_TB_MAE_Perfil_Usuario] PRIMARY KEY CLUSTERED 
(
	[PEUS_USUA_Codigo] ASC,
	[PUES_PERF_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TB_MAE_TipoEntidad]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MAE_TipoEntidad](
	[TIEN_Codigo] [int] NOT NULL,
	[TIEN_Identificador] [char](4) NULL,
	[TIEN_Nombre] [varchar](100) NOT NULL,
	[TIEN_Descripcion] [varchar](500) NOT NULL,
	[TIEN_Token] [uniqueidentifier] NOT NULL CONSTRAINT [DF__TB_MAE_Ti__TIEN___3B40CD36]  DEFAULT (newid()),
 CONSTRAINT [PK_TB_BPM_TipoEntidad] PRIMARY KEY CLUSTERED 
(
	[TIEN_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MAE_Usuario]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MAE_Usuario](
	[USUA_Codigo] [int] NOT NULL,
	[USUA_ARCH_Codigo] [int] NULL,
	[USUA_Activo] [bit] NOT NULL CONSTRAINT [DF__TB_MAE_Us__USUA___5AEE82B9]  DEFAULT ((1)),
	[USUA_UltimaConexion] [datetime] NOT NULL CONSTRAINT [DF__TB_MAE_Us__USUA___5BE2A6F2]  DEFAULT (getdate()),
	[USUA_Email] [varchar](100) NOT NULL,
	[USUA_NombreCompleto] [varchar](250) NOT NULL,
	[USUA_TIDE_Codigo] [int] NOT NULL,
 CONSTRAINT [PK_TB_MAE_Usuario] PRIMARY KEY CLUSTERED 
(
	[USUA_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MOT_AutenticadorExterno]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MOT_AutenticadorExterno](
	[AEXT_USUA_Codigo] [int] NOT NULL,
	[AEXT_Identificador] [varchar](1000) NOT NULL,
	[AEXT_TIAU_Identificador] [char](5) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MOT_Comentarios]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MOT_Comentarios](
	[COME_RUTA_Codigo] [int] NOT NULL,
	[COME_USUA_Codigo] [int] NOT NULL,
	[COME_Comentario] [varchar](500) NOT NULL,
	[COME_Fecha] [datetime] NOT NULL,
 CONSTRAINT [PK_TB_MOT_Comentarios] PRIMARY KEY CLUSTERED 
(
	[COME_RUTA_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MOT_ContadorSocial]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MOT_ContadorSocial](
	[SOCU_USUA_Codigo] [int] NOT NULL,
	[SOCU_Seguidores] [int] NOT NULL,
	[SOCU_Siguiendo] [int] NOT NULL,
	[SOCU_MeGusta] [int] NOT NULL,
 CONSTRAINT [PK_TB_MOT_ContadorSocial] PRIMARY KEY CLUSTERED 
(
	[SOCU_USUA_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TB_MOT_Coordenada]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MOT_Coordenada](
	[COOR_RUTA_Codigo] [int] NOT NULL,
	[COOR_Latitud] [decimal](18, 9) NOT NULL,
	[COOR_Longitud] [decimal](18, 9) NOT NULL,
	[COOR_Altitud] [decimal](18, 5) NOT NULL,
	[COOR_Velocidad] [decimal](18, 5) NOT NULL,
	[COOR_Distancia] [decimal](18, 5) NOT NULL,
	[COOR_Duracion] [decimal](18, 5) NOT NULL,
	[COOR_Fecha] [datetime] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TB_MOT_Foto]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MOT_Foto](
	[FOTO_RUTA_Codigo] [int] NOT NULL,
	[FOTO_ARCH_Codigo] [int] NOT NULL,
	[FOTO_Portada] [bit] NOT NULL,
 CONSTRAINT [PK_TB_MOT_Foto] PRIMARY KEY CLUSTERED 
(
	[FOTO_RUTA_Codigo] ASC,
	[FOTO_ARCH_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TB_MOT_MeGusta]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MOT_MeGusta](
	[RUCO_RUTA_Codigo] [int] NOT NULL,
	[RUCO_USUA_codigo] [int] NOT NULL,
	[RUCO_Fecha] [datetime] NOT NULL,
 CONSTRAINT [PK_TB_MOT_MeGusta] PRIMARY KEY CLUSTERED 
(
	[RUCO_RUTA_Codigo] ASC,
	[RUCO_USUA_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TB_MOT_Notificacion]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MOT_Notificacion](
	[NOTI_Codigo] [int] IDENTITY(1,1) NOT NULL,
	[NOTI_USUA_Codigo] [int] NOT NULL,
	[NOTI_TINO_Identificador] [char](4) NOT NULL,
	[NOTI_Texto] [varchar](250) NOT NULL,
	[NOTI_Fecha] [datetime] NOT NULL CONSTRAINT [DF_TB_MOT_Notificacion_NOTI_Fecha]  DEFAULT (getutcdate()),
	[NOTI_Leida] [bit] NOT NULL CONSTRAINT [DF_TB_MOT_Notificacion_NOTI_Leida]  DEFAULT ((0)),
	[NOTI_Token] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TB_MOT_Notificacion_NOTI_Token]  DEFAULT (newid()),
	[NOTI_Imagen] [varchar](2048) NULL,
	[NOTI_Contexto] [varchar](1000) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MOT_Ruta]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MOT_Ruta](
	[RUTA_Codigo] [int] IDENTITY(1,1) NOT NULL,
	[RUTA_USUA_Codigo] [int] NOT NULL,
	[RUTA_Inicio] [datetime] NOT NULL,
	[RUTA_Fin] [datetime] NOT NULL,
	[RUTA_Duracion] [int] NOT NULL,
	[RUTA_Pausas] [int] NOT NULL,
	[RUTA_Distancia] [decimal](18, 5) NOT NULL,
	[RUTA_Velocidad] [decimal](18, 5) NOT NULL,
	[RUTA_Calorias] [decimal](18, 5) NOT NULL,
	[RUTA_TISE_Sensacion] [int] NOT NULL,
	[RUTA_Token] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TB_MOT_Ruta_RUTA_token]  DEFAULT (newid()),
	[RUTA_Latitud] [decimal](18, 9) NOT NULL,
	[RUTA_Longitud] [decimal](18, 9) NOT NULL,
	[RUTA_Altitud] [decimal](18, 5) NOT NULL,
	[RUTA_Imagen] [varchar](2048) NOT NULL,
	[RUTA_Fecha] [datetime] NOT NULL CONSTRAINT [DF_TB_MOT_Ruta_RUTA_Fecha]  DEFAULT (getutcdate()),
	[RUTA_TIDE_Codigo] [int] NOT NULL,
 CONSTRAINT [PK_TB_MOT_Ruta] PRIMARY KEY CLUSTERED 
(
	[RUTA_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MOT_RutaCompartida]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MOT_RutaCompartida](
	[RUCO_RUTA_Codigo] [int] NOT NULL,
	[RUCO_Nombre] [varchar](500) NOT NULL,
	[RUCO_Observaciones] [varchar](500) NULL,
	[RUCO_Fecha] [datetime] NOT NULL CONSTRAINT [DF_TB_MOT_RutaCompartida_RUCO_Fecha]  DEFAULT (getdate()),
	[RUCO_MeGusta] [int] NOT NULL,
 CONSTRAINT [PK_TB_MOT_RutaCompartida] PRIMARY KEY CLUSTERED 
(
	[RUCO_RUTA_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MOT_Seguidor]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MOT_Seguidor](
	[SEGU_USUA_Codigo] [int] NOT NULL,
	[SEGU_USUA_Codigo_Seguidor] [int] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TB_MOT_Siguiendo]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MOT_Siguiendo](
	[SIGUI_USUA_Codigo] [int] NOT NULL,
	[SIGUI_USUA_Codigo_Siguiendo] [int] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TB_MOT_TipoAutenticador]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MOT_TipoAutenticador](
	[TIAU_Identificador] [char](5) NOT NULL,
	[TIAU_Nombre] [varchar](500) NOT NULL,
 CONSTRAINT [PK_TB_MOT_TipoAutenticador] PRIMARY KEY CLUSTERED 
(
	[TIAU_Identificador] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MOT_TipoDeporte]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MOT_TipoDeporte](
	[TIDE_Codigo] [int] NOT NULL,
	[TIDE_Nombre] [varchar](50) NOT NULL,
	[TIDE_Descripcion] [varchar](500) NOT NULL,
 CONSTRAINT [PK_TB_MOT_TipoDeporte] PRIMARY KEY CLUSTERED 
(
	[TIDE_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MOT_TipoNotificacion]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MOT_TipoNotificacion](
	[TINO_Identificador] [char](4) NOT NULL,
	[TINO_Nombre] [varchar](200) NOT NULL,
 CONSTRAINT [PK_TB_MOT_TipoNotificacion] PRIMARY KEY CLUSTERED 
(
	[TINO_Identificador] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TB_MOT_TipoSensacion]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TB_MOT_TipoSensacion](
	[TISE_Codigo] [int] NOT NULL,
	[TISE_Nombre] [varchar](50) NOT NULL,
	[TISE_Token] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TB_MOT_TipoSensacion_SENS_Token]  DEFAULT (newid()),
	[TISE_Identificador] [char](4) NULL,
 CONSTRAINT [PK_TB_MOT_TipoSensacion] PRIMARY KEY CLUSTERED 
(
	[TISE_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[FN_MAE_SEPARAR]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		David Antonio Muñoz Gaete
-- Create date: 2015.06.07
-- Description:	Separa una línea de caracteres de acuerdo al 
--				caracter definido por el usuario (SPLIT)
-- =================================================================
CREATE FUNCTION [dbo].[FN_MAE_SEPARAR] (
	@SEPARATOR	CHAR(1), 
	@DATA		VARCHAR(8000)
)
RETURNS TABLE
AS
RETURN (
    WITH Pieces(pn, start, stop)  AS  (
      SELECT 1, 1, CHARINDEX(@SEPARATOR, @DATA)
      UNION ALL
      SELECT pn + 1, stop + 1, CHARINDEX(@SEPARATOR, @DATA, stop + 1) 
      FROM Pieces 
      WHERE stop > 0 
    ) 
 
    SELECT 
		pn,
		SUBSTRING(@DATA, start, CASE WHEN stop > 0 THEN stop-start ELSE 512 END) AS s
    FROM 
		Pieces

  )
















GO
/****** Object:  View [dbo].[VT_Documentos]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VT_Documentos]
AS
	
	SELECT
		DOCU.DOCU_Token,
		DOCU.DOCU_Identificador,
		DOCU.DOCU_Fecha,
		TIDO.TIDO_Token,
		TIDO.TIDO_Nombre,
		TIDO.TIDO_Identificador,
		ESTA.ESTA_Token,
		ESTA.ESTA_Nombre,
		ESTA.ESTA_Identificador,
		ENTI.ENTI_Token,
		ENTI.ENTI_Identificador,
		TIEN.TIEN_Token,
		TIEN.TIEN_Nombre,
		TIEN.TIEN_Identificador,
		(SELECT TOP 1 
			BITA_Observacion 
		FROM 
			TB_BPM_Bitacora BITA 
		WHERE 
			BITA.BITA_DOCU_Codigo = DOCU.DOCU_Codigo 
		ORDER BY
			BITA.BITA_Fecha DESC) as BITA_Observacion
	FROM
		TB_BPM_Documento		DOCU	INNER JOIN
		TB_BPM_TipoDocumento	TIDO	ON TIDO.TIDO_Codigo	=	DOCU.DOCU_TIDO_Codigo	INNER JOIN
		TB_BPM_Estado			ESTA	ON ESTA.ESTA_Codigo	=	DOCU.DOCU_ESTA_Codigo	INNER JOIN
		TB_MAE_Entidad			ENTI	ON ENTI.ENTI_Codigo	=	DOCU.DOCU_ENTI_Codigo	INNER JOIN
		TB_MAE_TipoEntidad		TIEN	ON TIEN.TIEN_Codigo	=	ENTI.ENTI_TIEN_Codigo
	




GO
/****** Object:  View [dbo].[VT_MOT_Rutas]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[VT_MOT_Rutas]
AS
	
	SELECT TOP 9999999
		RUTA.RUTA_Token,
		RUTA.RUTA_Inicio,
		RUTA.RUTA_Fin,
		RUTA.RUTA_Altitud,
		RUTA.RUTA_Latitud,
		RUTA.RUTA_Longitud,
		RUTA.RUTA_Calorias,
		RUTA.RUTA_Distancia,
		RUTA.RUTA_Duracion,
		RUTA.RUTA_Pausas,
		RUTA.RUTA_Imagen,
		RUTA.RUTA_Velocidad,
		RUTA.RUTA_Fecha,
		(CASE 
			WHEN RUCO.RUCO_RUTA_Codigo IS NULL THEN 0
			ELSE 0
		END) as Compartida,
		RUCO.RUCO_Nombre,
		RUCO.RUCO_MeGusta,
		RUCO.RUCO_Observaciones,
		RUCO.RUCO_Fecha,
		ENTI.ENTI_Token,
		ENTI.ENTI_Identificador,
		TISE.TISE_Nombre,
		TISE.TISE_Identificador,
		TISE.TISE_Token
	FROM
		TB_MAE_Entidad			ENTI	INNER JOIN
		TB_MOT_Ruta				RUTA	ON ENTI.ENTI_Codigo = RUTA.RUTA_USUA_Codigo		INNER JOIN
		TB_MOT_TipoSensacion	TISE	ON TISE.TISE_Codigo = RUTA.RUTA_TISE_Sensacion	LEFT JOIN
		TB_MOT_RutaCompartida	RUCO	ON RUTA.RUTA_Codigo	= RUCO.RUCO_RUTA_Codigo
	ORDER BY
		RUTA.RUTA_Inicio DESC, RUCO_MeGusta DESC




GO
/****** Object:  View [dbo].[VT_MOT_RutasPopulares]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[VT_MOT_RutasPopulares]
AS
	
	SELECT TOP 9999999
		RUTA.RUTA_Token,
		RUTA.RUTA_Fecha,
		RUCO.RUCO_Fecha,
		RUTA.RUTA_Altitud,
		RUTA.RUTA_Latitud,
		RUTA.RUTA_Longitud,
		RUTA.RUTA_Distancia,
		RUTA.RUTA_Duracion,
		RUTA.RUTA_Pausas,
		RUTA.RUTA_Imagen,
		RUTA.RUTA_Velocidad,
		RUCO.RUCO_Nombre,
		RUCO.RUCO_MeGusta,
		RUCO.RUCO_Observaciones,
		ENTI.ENTI_Token,
		ENTI.ENTI_Identificador
	FROM
		TB_MAE_Entidad			ENTI	INNER JOIN
		TB_MOT_Ruta				RUTA	ON ENTI.ENTI_Codigo = RUTA.RUTA_USUA_Codigo		INNER JOIN
		TB_MOT_RutaCompartida	RUCO	ON RUTA.RUTA_Codigo	= RUCO.RUCO_RUTA_Codigo
	ORDER BY
		RUCO_MeGusta DESC, RUCO.RUCO_Fecha DESC






GO
/****** Object:  View [dbo].[VT_TipoDocumentos]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[VT_TipoDocumentos]
AS
	
	SELECT 
		TIDO_Nombre,
		TIDO_Descripcion,
		TIDO_Identificador,
		TIDO_Token
	FROM
		TB_BPM_TipoDocumento
	



GO
/****** Object:  View [dbo].[VT_Usuarios]    Script Date: 06/11/2015 11:15:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[VT_Usuarios]
AS

	SELECT
		ENTI.ENTI_Token,
		ENTI.ENTI_FechaCreacion,
		ENTI.ENTI_Identificador,
		ARCH.ARCH_Token,
		USUA.USUA_Codigo,
		USUA.USUA_Email,
		USUA.USUA_NombreCompleto,
		USUA.USUA_UltimaConexion,
		USUA.USUA_Activo
	FROM 
		TB_MAE_Entidad		ENTI	INNER JOIN
		TB_MAE_TipoEntidad	TIEN	ON TIEN.TIEN_Codigo			=	ENTI.ENTI_TIEN_Codigo	INNER JOIN
		TB_MAE_Usuario		USUA	ON USUA.USUA_Codigo			=	ENTI.ENTI_Codigo		LEFT JOIN
		TB_MAE_Archivo		ARCH	ON USUA.USUA_ARCH_Codigo	=	ARCH.ARCH_Codigo	







GO
INSERT [dbo].[TB_BPM_Estado] ([ESTA_Codigo], [ESTA_TIDO_Codigo], [ESTA_Nombre], [ESTA_Token], [ESTA_Descripcion], [ESTA_Identificador]) VALUES (1000, 1, N'Registro de Inspección', N'0620dc12-1435-41dc-bb74-1c998b0264e3', N'Registro de una Inspección realizada por un inspector', N'CREA')
INSERT [dbo].[TB_BPM_Estado] ([ESTA_Codigo], [ESTA_TIDO_Codigo], [ESTA_Nombre], [ESTA_Token], [ESTA_Descripcion], [ESTA_Identificador]) VALUES (2000, 2, N'Solicitud de Inspección', N'a62537d4-720c-42cd-be71-ffd2d59b606e', N'Solicitud de Inspección creada a través de alguna compañia', N'INGR')
INSERT [dbo].[TB_BPM_TipoDocumento] ([TIDO_Codigo], [TIDO_Nombre], [TIDO_Descripcion], [TIDO_Identificador], [TIDO_Token]) VALUES (1, N'Esquema de Inspeccion', N'Configuración de Esquema de Inspeccion para una empresa', N'ESTQ', N'e98e532c-04f3-4d5b-b92f-ff845661c85e')
INSERT [dbo].[TB_BPM_TipoDocumento] ([TIDO_Codigo], [TIDO_Nombre], [TIDO_Descripcion], [TIDO_Identificador], [TIDO_Token]) VALUES (2, N'Esquema de Solicitud de Inspeccion', N'Configuracion de un Esquema para una solicitud de Inspeccion', N'SOTQ', N'55684b05-62ff-438e-81a5-8e0ca9d870bb')
INSERT [dbo].[TB_BPM_TipoDocumento] ([TIDO_Codigo], [TIDO_Nombre], [TIDO_Descripcion], [TIDO_Identificador], [TIDO_Token]) VALUES (3, N'Solicitud de Inspección', N'Solicitud de Inspección', N'APPL', N'f01c4e62-5876-49ab-ac8d-c42e43599821')
INSERT [dbo].[TB_BPM_TipoDocumento] ([TIDO_Codigo], [TIDO_Nombre], [TIDO_Descripcion], [TIDO_Identificador], [TIDO_Token]) VALUES (4, N'Registro de una Inspección', N'Registro de Inspección realizada por Inspector', N'INSP', N'ba3e26fd-eb5f-48c5-8ea9-1feade7e8490')
SET IDENTITY_INSERT [dbo].[TB_MAE_Archivo] ON 

INSERT [dbo].[TB_MAE_Archivo] ([ARCH_Codigo], [ARCH_Nombre], [ARCH_Tamano], [ARCH_FechaCreacion], [ARCH_ContentType], [ARCH_Temporal], [ARCH_Token]) VALUES (1046, N'Profile Photo', 15711, CAST(N'2015-11-04 02:12:46.913' AS DateTime), N'image/png', 0, N'40b8f32f-566b-4de2-8f2c-7463d79c220f')
INSERT [dbo].[TB_MAE_Archivo] ([ARCH_Codigo], [ARCH_Nombre], [ARCH_Tamano], [ARCH_FechaCreacion], [ARCH_ContentType], [ARCH_Temporal], [ARCH_Token]) VALUES (1047, N'Profile Photo', 10757, CAST(N'2015-11-04 12:06:01.730' AS DateTime), N'image/png', 0, N'cdb1e951-f5c6-4df4-ba04-68dccaa76a8c')
INSERT [dbo].[TB_MAE_Archivo] ([ARCH_Codigo], [ARCH_Nombre], [ARCH_Tamano], [ARCH_FechaCreacion], [ARCH_ContentType], [ARCH_Temporal], [ARCH_Token]) VALUES (1048, N'Profile Photo', 11059, CAST(N'2015-11-04 12:14:46.220' AS DateTime), N'image/png', 0, N'cd13a4ba-e24a-481b-81a9-0a1c2c9716b9')
INSERT [dbo].[TB_MAE_Archivo] ([ARCH_Codigo], [ARCH_Nombre], [ARCH_Tamano], [ARCH_FechaCreacion], [ARCH_ContentType], [ARCH_Temporal], [ARCH_Token]) VALUES (1049, N'Profile Photo', 12652, CAST(N'2015-11-04 12:24:25.427' AS DateTime), N'image/png', 0, N'94e7f368-52d2-4a55-a0d4-6f46729e648d')
INSERT [dbo].[TB_MAE_Archivo] ([ARCH_Codigo], [ARCH_Nombre], [ARCH_Tamano], [ARCH_FechaCreacion], [ARCH_ContentType], [ARCH_Temporal], [ARCH_Token]) VALUES (1050, N'Profile Photo', 10000, CAST(N'2015-11-04 12:28:51.663' AS DateTime), N'image/png', 0, N'cd6ed9e2-bc39-4a70-8b16-49f694304a70')
SET IDENTITY_INSERT [dbo].[TB_MAE_Archivo] OFF
INSERT [dbo].[TB_MAE_ArchivoBinario] ([ARCH_Codigo], [ARCH_Binario]) VALUES (1046, 0xFFD8FFE000104A46494600010200000100010000FFED009C50686F746F73686F7020332E30003842494D04040000000000801C0267001479794D4F574C79327A7671393569377A78516A381C0228006246424D4430313030306163323033303030303733303830303030306530663030303062653130303030306635313130303030636631363030303038373232303030303965323330303030633432353030303038643237303030303566336430303030FFE2021C4943435F50524F46494C450001010000020C6C636D73021000006D6E74725247422058595A2007DC00010019000300290039616373704150504C0000000000000000000000000000000000000000000000000000F6D6000100000000D32D6C636D7300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000A64657363000000FC0000005E637072740000015C0000000B777470740000016800000014626B70740000017C000000147258595A00000190000000146758595A000001A4000000146258595A000001B80000001472545243000001CC0000004067545243000001CC0000004062545243000001CC0000004064657363000000000000000363320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000074657874000000004642000058595A20000000000000F6D6000100000000D32D58595A20000000000000031600000333000002A458595A200000000000006FA2000038F50000039058595A2000000000000062990000B785000018DA58595A2000000000000024A000000F840000B6CF63757276000000000000001A000000CB01C903630592086B0BF6103F15511B3421F1299032183B92460551775DED6B707A0589B19A7CAC69BF7DD3C3E930FFFFFFDB00430006040506050406060506070706080A100A0A09090A140E0F0C1017141818171416161A1D251F1A1B231C1616202C20232627292A29191F2D302D283025282928FFDB0043010707070A080A130A0A13281A161A2828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828FFC2001108016300C803002200011101021101FFC4001B00000203010101000000000000000000000203010405000607FFC4001A010003010101010000000000000000000000010203040506FFC4001A010003010101010000000000000000000000010203040506FFDA000C03000001110211000001F57305D9F3513D213DD2899121B06615B9F49D3ADA770E7DCC20AA3B15CC6B10B34D8F3BB50615C9550AC1F0B7067744E9C85C3232909449048347A55B5A1627A2C36AC67DA2D0379057B02F3ACD495E0EAFC22288072729E25321359170C84F448192A5536CA0676B5A1969C7BAD330C85B4CA8B6EDD9CCB159AEE51B8E61178275CD025EDE774F092821EA8991209E88194C720ABCE5E5D5AAAC7B91D4DD6CBB8D567030417D4B9BBD31DAF2912B850BE0ACA3A25E75E466A0A238645100C9512AA79763479FD0A27EBA846ED69B9E95333D0F079BADEC3CB38D06646AD73ADB5BB5E58195BCA6239CA7A39C974730F865131C09E2FB3F0FEA30F57D0966598EA076239E5BA74993BB2899D65E6B4A9334E168706BC731C249C74024972D170C8A7833D5EA273795BBD3798DC8EDB4EF25AF874DBCBDCCFD733D2C34675EA6965D8667D8CBABB726D502B66544F44AF3CF63142748F3CCAA21AB5AD75F829EB54CCECFA35F456F8DF05D7685ADF1659A9A55362BC5D533D78AA181B1E3EB255AA1AD468DE43B5E028E879AA8B4A77EB1D6DCE6607D53C273FA5846B373E875FC97ACCB4C25EAD3A2EDFC6B6E58BB52ABB5534B3BC9CC06699E7B762ADCD5D3C8B158EF425BB7053B5BB532EEAF7D981CFD4CF39732460E7DFD23176709C2F46B45C926836A37BB6321AA6EE1D7A2AB97D1AC73AA4B57E6940B7B4F0EE3C3E9018D81C9ED5D0ADBCB3F17BFA79759EBABCBE38AD8501DF9FD63726CCA0A0FCF64E9E4B189155A655338624CF8566BEFBB5E4C3BB8E59F4FA7A277F93B6B32FD042732AA35C54EACFD25132C6458A5689E8BB4130512E8B2C8E49C03CD192CDAD1D7F327A73E8F9DF4FD596FE9675EF3BDDABE7FDDFCF4CFCC7391BE13611D4ADD5BD484C9AB2CBB4D463359434D35CA2C715725C75CD8C64CDCCF490B4AD5BF29E5747A9C08DF5AF869B17BB70C6995E8682279CD2EEE28E4040A24996AA31696AD20814DA43A871832A24C6056B0B787C9E8F49E3BD77CFB2DB48F223D3E6D8ACBB74B383D2F99753112CE89962EF51723A256062F583DAA654B8C0EA08A39AF42CCEF37E1ED14495E8519406C98DAE4D3456605110331E86148F208480260A0765956DB96B52EA839E96A869E2FA2F2AFCF506075DF4C4EAA1AA2A0A465043301DD22C29124FBB9A80868A6ABF4AE836E2AC5E63DD153836EAD7CDB13325F3ABE9852E280022860C4C0DE8820E9914CDA132C66C44D45EAF64569661A441A66A70D17809ABD3AED651E96421E0253A4C8CA65C3CC987D86ABDD2E12C1CECF47FA3DFD5E6EEF3B8BEF3ACF9927EA6379FC987DF63DE5E1A86EE16BC03A351CF4BD9770C9CF3D0257426F43136465A2E830E0952A62D4CCF4D4FA7FC83DB63D3EC3BB9F477770772A92CFE6D4399D7E54734274186C02F885A1EE861488B18558668A25B1533329AF5AA271DBECBD59F3D643182E737CD6857AE4C7203DB129199087A19006BA1A995B5235C06F5B086D253C26419150D5FA6C37F5BA1C53D3DDDDA0B559E93E2DD31BF9CCEEE4A448404646D2D0FAE156CD7B0ADAC5B2E21E87CB962D9151F5DF917D7F9FA9DDDD7B444C08BBB9BFFFC4002B1000020201030304020203010100000000010200031104122110314105132022303223421424331543FFDA0008010000010502F9881B9310AC755DBFACE5678E084E59BF7EE4041108C1FB3358607C4C8FC2277827909F50B2C6C0E57A1EFE546F7ECBBB83D3CF41F1CC538E883ECB89880E631E7FBBA9C64C10705BA1EFFD7F0B1C9CF3CB4A472C706B6FE46EFF00FC95C09698BDFBC3DC427108FC0398A46571B92B5DDB4E5381636D7AAD119BEC5F21A6E5DBBB9FEC1011EDB4207E30C36A9C13A90A6CD4282AD9B7F5B5ADC51EFF00B516CF7019E5089EEAEDB2DFAF7FC973E2694D6D6EA34CCA51361AAAFE3EC6D60454C652C77E6786ECA570F8DC4C1F86D6DAB75A490C777BA48510AB23E393518ACBEFE7F946E6465C4CF1839E31E7E7E117736B729154B414902B4FBAE907B75E9E6A68180865AA516AB4A369EFDCAC0B106540B96183F841C4D63EE6D0E9CFB8546195777B8567B99832CAB5810AA91AC515594F2AA576F1911F3F8DBED669C7B75048CB908C194604F30CBAB564ADB6B31067133F8DBF55397AEF688FA986C6C5B6057AB501823C62D2C66DA7EC350E8203F5FC79963A85D2805CB7B552B86088CE75BA472BA76C0A9F07DC95B8275CD11BDE3658AB0EA14D3EFDCD0597C175820D4AE3E04E23EA44D97D90E9F09A661EE6AC8F68D8669F5BB56AD4C29FCAF532AB19A46FE4D5FD9EB66A930CEB4ED502C1D5AA46F85B7048A965D1112A06F411EFC8A93219F359519A7E8E7682DFBBD9BE6C134F56013B988AE9D36A6C16217DA45E48D2B129F0B6DC9AE9C74BADDC733773A05DC97FF1C7AB08325917231B600A61AD181C6E440ABAB41FE313F53DE8F6E215E9E25AE49AABD9D35076D6DDE34F4E69A81B8370D9E4583603F42C773F2685E58E1356E3DCD5BE9CB6010071B8ACA2DDDD2C6E2A4DA25151B5F657B7D5695A2EF204D3DB8B37E458A0C2822563079898DB561A0204D45D85D59DC69A6B2897E9AB5D46A05CB88389536E5AD72D28A8DAD758BA74173B36AAE373C5EC4E0E9EE247B8B05F46EF7C88753623D2E27BEB1EDC0D45D984CE4367139115E07FBD0769FF0008053A5B32DFEAD0F9B5B576ED8651A7B2E3A8D15DA7A8CD3925E9ADED034D5CBAB6A8D8038A5D526AF6D65ECE19A1650C3904F4FEB5CA8E7A33051A8B7DDB2EA6E4A29D25D73AFA4A2917D542D9AC46ACD3543B04A6CC81B49D49209386A6D656D45DBCDBCB184662FF00CD873E3494FB8F756D51AECCCB751ED07D433C4FB4AB55B11F5670F71616DA1059764EF315B9D35821DFBF5966E39E2BFE36B2C8BFB7786626D9B79D10FE3D4542EAD9592DD6BE6D580CDD1EE0A2DD54662CEE21333F6479EE13399CC2E6195761DCCCC3077AAED915C32FA8265397B6AAE3D5C1ACEEBC86BDF823BEE2D0C2A02F9AA6258F9247113F4F24C1D3C4166D35DCB68A348CE174BB65C489A9B8D4A6336403166D8386DB981F696B32BD3B98089919FAC3DE64B4500430FA80029B43C7FD7D68FF00B45B8F2712AEF2C1CE616CCCCE6133C32E52AE5ACACA43DD264B95E20E9FE2DB5E9F4F6FB66DD7F3AFA6EADCF30212710101BC590C114CCE0E381370C0EEF66F48227683A6AAC4BA5F673A0D9EF7AEDEAD554998C76C7E1E29E1CE54F10F057BF5F0BDF8C030453D074D759B1FB9F49D2AD7A4D55805D5B44B034352323D455CF04987B98BDDA0E23A8DC20E2733CA7651F0BA8F7751E9DA5FF2351EADABF6EA6333C038896E0D1A9DB77A8EA28BA89E0F3D33F6111B933B1CCC98B17F6EB752CECF755A3D3DF69B5F30727A29E19A09E0F4F1074339E959E3CC1D353AE31DDED63D13E3E279E86783F04E80C506625E72DA5AF6D3AA415DBF83C79F8639C1988870DE2A989811CFD9EC0B5D84965E0CC71D441D3CF41C18071BBA11F6512A5FB746E4ABE45BFB742B8598E99EABFF003F803C791144022F0A609740C44639E822FDAB03333D310AC18C433BCC4F138336C48917B1E8E3A78026D88F89BBEF9EB99DE6D98888DB8A83635627B6D34FA0BAE9A7F46027FE4E9B177A65954F65C06422112E1C929B04D1D5C6A6A545C753D874EF056C657573D3389539ADB43AA5D4D7F02019ACF4E4B66A061BA51A835CD458B62183A7815B182A02281D5BA0E60386D1DE68B68B56EABE3AD48D110922930553DB59B5474333D3C99FD73C710E4C038433D0AFF8D8DB56CB411800CC41F80C078DD820738E83BFA7D9ED6ABA9389EADAACF41F03F3CE616D84761073D14669432B7CA6619AA5D4D92CA9960F998B0F726778E4C41883A0E8DC0A865D579031D5915A0EA3AF880CB0C63B603B8631D17E0DDBD2746D63AA851F03C743DCF7F83F611BFE8BD8778279E9FDA80057D0C1D3FFC40026110002020103030403010000000000000000010211031012212031411322306104325181FFDA0008010211013F01D51E084FDB4D0A32893C9B1FF49BB8D18E5F56C9E4524933D6927646E5E7A7E8C71B6921644A542BB66451ADD164494AD8D97D09D1171557C98EA1CA17B5DA3FD37ECBE0C2F9A64F162ABB1F561C7E5F45124D0A54ED1277D29ABE4C71F0894290A38FB8F16E771326370E49CAFDAC8CA9F24BBF1D2BB909288A716853FE8B22A1B5233BE06FA545B1462BBB20AB93793DB77114C9CAD5138A7DC9DC7C1BFE8B8BF1A6D51E64453C8471451B691DCAF250A3B8CB8FDD7A4D54B44B62B7DC5173742FC6F4A3A5946DF038F22E381F2E89C76BA24B72A64B8744FF001B2DF63162F457D9397836BEE5966E659B8BD678D499EA1C4BB95088F33F1ADF4BCD53FA134CEEC7C0DEB4574CF16E2391E3F6B22E2655F1D0F895212B8B6CBF81EA9EE95232B5FAA2B4E3A9EB0695ECF3F13D61C7C4D0F4ABD1BEBA1A28A22C9E4D8ACC73535D1659164631AB438263C0878A48C32DD125152E24422A0A91B8DC5BD5189F8D65351218D43B145145695A223A49BF034FCF556A8C71BE95AA25AA3176D3CE9FFFC40023110002020105000301010100000000000000010211100312202131304151041333FFDA0008010111013F01E2D1D0958862546DE6CAC2FCF85D92676CB3D24272E7397D71585C9FE8A45B2C5D91F81C24FC36B45147843DE56766A3BE8511794C6888845158F46F69B997B85D7A5E2E884BAC2C7A3747FA6E78659B8B1B23D213B3C17629A3535373A20BECB1A28A5851BE09B46E175E9BFF000516F290F828DA1A3C47A462B2C4EF8A65290C5ED714AB9C751CBDF494E519AA2C5CD660969692933F96F526F50A2989BFBE4B2F4F535A96A74910828AA5F27F6A9492847ECD28B8C527F0D8B15F032C4C4CBC243E3B492FC36C9FAC51AF04D9BF09D0FB36B3614B2FB1F06D1B8DC59786F0C90A699B91B93F07F033525442158DA85C638631FF00D387FFC400331000010303020503030302070000000000010002111021311241202230516103327113819172A1B12342243340626382C1FFDA0008010000063F02E81F343A948CA866E8548A42CD2CA05850F7E8F7AC21B2F0A380C56D8ADF1D1C4D21D653B2D53513852A2B9EACAB5949C22A1AAD85E6970ADDBAF71657C2209F8507F3437953B9D95EC9BA55ECAE1484DA1B75088CEF40230B90C93BA03CE51D1260E42919C2D11CDB9524FC2814E7C8A72F561B9443D360EB07109DAB385A87B86CAC9C47B894078A1EE77A0B2E795CB308474ACB255940E51BC210B90D09916DD0D1618F851E99D4DC20215ECA269E55FA30141CA71178570B4C211EE5CFF85A9BF7A48C2D5847979BBA179B22A3B28E9DCCA25F9A4DD415657A6022D60B384A113A95ACE563645737506E5735D10807FB8595B809F6B87F7764ED0E880ACBCF50D069662C1619F8576144EFD9629CA55919C286B4483EE57107AA6FB20BB7C2B15EE308967315072B25732B1436511ED572AD90B95857B173315EDC3750CB957E54E25C4901059501C882DC58785994F23FBC4C7944CECA5AF3A50BFCA013DFFF0055A9DCAD5C98F2A0DAB768E0F2A5C74856FCD0A06716466415BF8593CCB97B5D35DE15F06DF0A0BA4FC2D57BA1AB184D66E6E569FDD729C2875D19D8F0E96E54BAEEAE6863B6EBFF0033FBAD6E803C9534684EE50B5074477D96868D43BCD949B9FE13DC32D2B4D0EABA86DB834B72BCEE6B6A81509B782A4956503150D79219BC2FF0E1C045E55D032AC6CAF5BE77A78DD69D2210FA7ED7091E14714A1164D2113169A874ECB5FAAE89C302877A5A9FF0835ADD2DCC2C59085E42D47ED4F1BAD0C46EB51C0B0AC9C285CCE850DD6E5CB007C22D7817BACD939B17DA924D3CD3B28516408FBAB39607E5465DBD3E930FEA348F49BA96A70E5DE0AFE17C291CACEEBFCC7A9D41CDC2D38EDE1366FB2E43375752AE8C5D1574519C0DD0F1492693E9B492EDC6CA18C3E4953EBFAB6EC169F49A1ADF09C1D8221733895C82106FFB6CA771909FFA847E29233B271B5C8985153DE93F6467DA0221DF629B3B595D413487ED4B95CCBC295F2A1DF656F4DC7E4A68ED9A0DD18CA93C0284F951BECA08821476E0BAB05BD6420BDC55AEAEADC7751B296AD632D4E71DE98500A741B0314BD4107823656A79533535B22D7654E02B10546928DB9CE15F2852D599134B52FC39A5D40A86B166F48F015D4AF352821C33BA029788A0DA381AFF0055EDBE06EB9D0633745FEADE4FBA86D4159A7856AFDA0A95E577E2058EE46F856DD7A7F570D2BD36B08337B2D5D94A3D29A65653B85C1B66D0BFD50097F7EC9FF4BD936A43859074F3145B13062DC22714943E9DC112A162EBDA8F2D2381C5CE86AFF89B95A1993C1743D432E332502C6C7AA4DEDC37A026811E32D6DA727B2D1E9E07EE8B9DBD3B2B708E8DF8A0AEF58FF4B2A777FF0008F6E11D2B715EA08ED017957EB4D3352AF5CF04F00ABFBE78638042B56456F581C3E6B8E33D291C37A8214DD402B0B95B03CAFEB7A93E1AADAE7BCAE4E71E15D8E1F658A045A33364656B77D948E80D95EF5BDD6A6ECAD670C8E1B85ABD2E4776D8A3358C84349E085D95CCAB7100D41ED4D7B307883A982AE40572B0BDA3A375E15914EF44FEA1C325444AC7521795273C1E99F3C3F4FD33F2782DD2F2AE2FC0EEE8140F8AE34B7C2323A975CB6DF8AC9A0F74D1E9E3BF07309E9795E7A3F55D660C795031C650E322A785A8018E2FFFC400281000030002020202020300030101000000000111213141516171108191A120B1C1D1F0F130E1FFDA0008010000013F21C8BE57C21A67946C3E824718A2DCF8841648FC9C20D2955D396C795F7917311E0091BB8A6B6C36F626B97B18BC2A2B7C548C0C00B4F36B2D4FCAFC7F5FC38F8F24A55FB237F33E0D723730846474B3816DD77A2ECC0A5316F79138EAC607DD2B51C8D84597A5B1B6CFD243672D06DFE8D8A2577E02D3F85B7BE0A705E3E1613816EEE89049D53674C72256155F66B91F8214D7D16991DA369C0A11119A74695D0DE70C862DDC09A6F2EBA1B1721B5537AA369BCFCF06DFC5F8A5684BD1095DC0A777E5E4C33E862DD8A41A3A14AB1D3C8D6CC73F845271026348F4DA1F2371AD8E8C17B1FC2937F1AF95E1C64C8DBA22C99D74313CC602927E422D8AF2D0BC76152EC8ABAA0ED996190482AAB635A63F48305E0D0AA8455D7F63DB49FA16A3605247EC764FFE16084A4DC97427395AD51C556F0C10FC8F49E0AC59B74137730DA094BC5A7B9D9C5B5CF1239B336E4B8B22E449A84FC8D3AF83A1652F490C48F06F19E069A37D1B1EB8F84F7FFC391B8CCE0AB0B185FE9207018BD0A8D0BD4B5BE6CEE3C3B2DC883709FD4340B74452C6392D640ED77B2FFB02189D6F1C0CEC953C8444E86C6FE69BFE0A45658FDB1C4FC998549F4855DCB42D7972CCC56F75099686088557442D15349A4CB22730CB968CD7EFCB1F32D98DDA3338F9D21CEBBD31B8796479AD3C0BE10F3BF95B1B57DD18ADCCD1A05E8C6E7DD91B1B1EBA10EA7265BA0C013A225C10465B26C922AD5F23D0D99C85F277C86A792BAC9A51ACB2CBCDD978E11317F8F1E7E58D538FB199462264A16B5F42F9C48691142E453A6F084EB842829A23AD104D8BD1BF505E076823567A8652D58BB1EBF01C2DBE1D8D7936FCF44F95BF94E33D7C3713192538937962B95614E4B67209E1192AB60495605C90D1A6C79302D742C740AD6C98DF115C7258E72FD171F93665B1BFF8FE49FC7EA0E6631C16A29C64FEC6D37F551AA7DE47E934D94DC8A592ECBB5FDB1C043156BB5B1657C9723CBD6BDAF81CA7B038AF1FE9A18F48B118135575FC29E4512B2C09269BA937F62E91236904162B2E4FD318D43F2474E4DAC0C4C284AB25E572272A108D1ACB5C0A99D2479D397930A970698B9A767447A11DB8C553F03C99D63E57C256B6859C185B9C0B7A31AE85F034E2FBC0C227C9365583E87E376C0FF62B96A92C16986626E287E3C4EF27106F1BF02ED6E26FC0C7F371FB263A954E9D6378FAF3DFA2CBCD9EC30F604293D191727C2C676510E32185DD3C98212F2D9A16DFA21569E2781EB11B8F66B8FC0B59113612F613D13C0BB1E15D8CD397302D2260BF2FFBA1AA6211351EA8F6BB48688856F166966F81EC7690D36659EA40C8EC4C110F4A6CEA827F16FF009F0DC43129AC227FCF43C2198EB5703CA249D8F927A10F34B1854FC32113CD78AC3EBFE47A2941FE172254F697FAFC9C06D2FC9B18F953D8E355E5E36417475879F90CDD9BA28D63D6E449D25C0C3098B751E09B61F8152B5D8B9251764F085A4F02734494F9D0DC5590357FD0B4EDC21466DE079B9171E4AC694C1E3BC1A5299DEA9CCEF25E27E434A39C8C6471A8D21E288981EE9EBB14C1D7D19D98162A63B7D09E0C174C68ED9B605C279FE0EB776C8C2CB7848CF64FB0891E3B7446DE1B544F6125FB165163D64637D62FD0DBDC224B8A3268FC2B30C1A242233CDD8EADC34A24138DE4B23475812576CF15B12B058DC433AA9B42FAFD60AE9794A89FE5DD17CDE429716042756136E8FCA57D8FC78EDBE8FF008E022CD86F7DE0E5467A2E6ECC21EC996F146136197223A51CE431253C35AFA341252C0A8C94D84EE30361610C71DAEEBA325DF02A2F1D99738594AB5B6704654233A5A65FF61253EA5CA30C9DE43ECA665880F358AABBA3FA1A96A5B99C1F9E5A9EC98F738148AA8C43147437E7D21E58DD2A9BFC09D42F24A35ED0CADA65BB128B9B587F6557FE014CB073C9ECE807F925E6A5AA7D0C41BC6F912BC6F862ABFE629133FB71FF000BE1B524915A6B839CB6CB02CEC302246652EB4CFD9214F4227539087F6B0C14A4E60F572357E130D0CEAE32707B2A563FC009F088B36AEFBA1CD5BC9E69C0CF4AD551E2595E5133EF6CE3A211F5449F034D4523EDE0B136BCBF07B2F67D322A37BD2F228CA3464C15630D0EE181F2834537D2E475D3B9CC13C9C4FF0043DC3CF01078B1BF9E476F16AA48CBA9B5C17038C6D7842D9146C5AE67D2E90F599668D13AB7048DF73A168F3A3FEC8C593DA14D451BC8787C7274396F2FFC2E7FD991B67BD1AE59954FFF0048AAACDE0CF5BBD90A9FB1350F918C99E9A17B662D434DAC6C495564AEDF46A345D98C4E90EA6754AC32A1C28FCB2C44FB3F60F38DC0ACCFA23F98F44D20CD9935F04E640E3337E8C1B2A255F07491D57C1C9BA9F060AB72859E8265FB1A579310D7B101E8859658587D1D1A0DB269B5B305D1FD9A5AC0F5D3BFB18DA4CA35D9129DAC872837791E89F4242BEE221BAD23D4E92F678D117264F8EC7924EA625A2F247ECB7A17EC24E365C51BEBA2FC9FFEA32D2519E1DE48D31989D6C40EEE63D99B512AB910D48A522375DC9CCD03AADE893EDEC51E05919172DFF03B308B84F3B2E8CA4579F43C9BE5E7025A7E8AA1CE192C3E8FF42D58696429A696FC98DC8DA961FB10AE62882C198404B9BC12D8B769562C06B89B9134CC131B2B4697A981C09634276B816E50FB452F462F06C0F2361F769D19A75D7ECBB26A5F718ED12F286AACA8460DCE0429E0DC49B7D8D2827D0BC6C1D9ED2D6220AD4286D797B108DF4F2CC82FA35B87E39FEC15084D8896CDE10DE289F1C8A7D8D63814FD517EC4129D432AE59830A211CB1E8B84373F3842B4E4C80C6268249A205EB6EB6B14B14567D18C1E05AB64F067D9F626A654E0DEA96FC16298449D2336338FE13B33D762F6E9972BB2329723E9936B3FA1E09ACBA9A2B5D86635BF6213CAB9F088E8C6429C15A1D6B76BA177E2E29C23F396F7F03DAADA64CE9CAC320DA1FE443006594EC95E07BBE28E994531F938D8921DCB98426E3C0A5C454444ED746DB1698A86F2B7D193C8F82943DAC0A14A27E86CBA43DE01F2C3EBC86210AFB317DB0379EB023DA9636EBC892B6F3A23D16DB96F9276C894AF1A348F42DB286939E3064631E3D885B118E0C963BD218DBA8B317087CF83825B6DCA2E4B91B8F1A19DD3DE0722DD2E9C0D79E4462E513D3C93142B928DE052A4F1E47DAF235C94D1E818B2B76354E408A4EEF1706F83EC51AF2D8AE8D787A27E3B1650F69DC0B347F4391EF239AFEF82F653E4C8F5463A712D7EC803CE2425E76276B82311897544831E08C55DE46F25F1D9CFB39D6BE2E20861BF02CE662CA2C37F879E56CDCEC6CAF839ECDF5F42AB970BD41466B48CC329B7C0E72C8DA4723B1CBB504CDA17656D2570300926B2629A35B21E52AC171F089A3844F8B564B89FB2298FB1D7951785307955165454F01ABCB915ECF2D0C9CC14BBD330189FE48D5F7B34BB43DF9B426F654457C0C49C3566D8744DACA6234937CE50935496455CA8469FA62A9E05B64733069DD130C4CB0D14C91924C69B758EAF0650A71246AA1E16CD658E9DC1F62DD582B98FC892698BECC3913DDA144184C5CBFC0C8E4724660D2FD91DB59CE026ACEC81E02205537B7C33F813F4E3C8E60872205C45E67CA1AAA7A1748C3C06973ADC48D8D8F42447D8D95F1231B11B7DA884B7F0738A364E078BD0ABCCE725A224BFF1FE29221AF28D23CBFF004420B64F0762C31552F7F07BCE83197A1722BA9DE070B1F637D37421854862D9E1A1B1A1F842AE1A7E4EE9F5DF818154FE3C7F2C9C3A630956034BF202B197D223DBEC4C60145A490CCCBE1606F47C90C2BB564BB95C744B85ACD28BF2FB16D3B9FF00D3F8A18CD10DC9D9C053D0ED1C791069B7F2DFC367060E7427CC3C259EA39F31FA1F69F0B99C3B27F38FE0B4C8D7C4E51FD0910BC8D74462099CFCB42F26C6E14D163C982DBF022C91988603813D564627C86EACA3C90339854AA937407D5DBCA3FA0BD64B81BCC47181ECC0CC65048DD0943C2E9D22154B0FC04ED962F7B1793610CDD72A2B0E8D8CDDAA5E105A7CA989F64344B70B2F43D5824598CCD1981AF379247585A56FC06AB89AED99DF6D9E7937C8E5C086700B3D8414D713F8F472767E823F787B1E9FB2D83660CFA19EBB693153734AC30C79322B6398C2D88DA9E9B421D88A25F08D0D3E3FFFDA000C03000001110211000010E3C5D33B63AD3152652C2B0EDDEE601AB10DF0E6976DFEAB8FD87C6B58E904C8CA530940EBB3B3E7EE583EFF007BB363366B66110DC0D42D2311DD3ABBC97165E8AAE08E0B1A731F92864747CF2D0377C8A2E64C4D1EEDBF51CDD34E06A81A0AAF5A9FAC0EF44BEC1878BFA3482CECAACC88BE679F11697ED48A971103B98870BA4FFB0AC2B77998AA7AD2BC18C783F9DEE3FA114E0AEB19059B218D822FB3F498195094E592B326CAE9522EDAAC6C58392DD9B4C576EB90F518370DA9DDECBD31ABCF2F507D17ED952E196DA8CA5ED59361D4B0E404F2C884F9CFEB557FC9A22F3FFFC40025110101010002020201050003000000000001001121311041516120718191A1C1B1D1F0FFDA0008010211013F101F049957977068AFC3EF6538E37AE780F7FDC18E74E6005D8C4399478BD69F3FADCC1DB1E80FD5CF1BC5B0DA7B70580BBE97FF0075FF0030EF9F0FEB1E4FAE7F895C67D4B0D0E6EAAC772FB9B0C3E35093781F2EFF008FF63EEA67D95ED380C248E0FCDB68CE4FA3EEC35CC3D4F9E09D2DC8B7C0343C72426F2711B3C399778D0F770369F16E53398EBC375607A41874DCE4DCC7ED1F483609663AF1FC7F1EB7F5B04E67C6F720474FC36E89ED5BA64671DAE4279339B0249336F8EBE60346D040E9BD4D8FDD221E6DD1622FF68F47FBB9F62EF3FDA203ECF893C5C0BD26DDE9DE010B1FB427A9BADA05C666659A64C9A648B07BA75171CACBAEEFCD903318CCAE07B81C59389B908103B91C01653B6C11E39F7F5F523DA10C1C5F0877DD2B76E1CDA399F1B4649EA045593D8E6119187C36DB7896771FA4069EE361A799966D9D3398C9EE098F49DC4E3040396C799E799388F8B1D9D7B82CB2497D586D7A93FB6067C93CB3C1C31D59CF8082E936E42FDC410F57B986F4C83A77C7B98B6F69276D57B377FEA39B2CB223C06F81CC96593CDBEE7F1CB236F7479B2E012372C1B9F191DD906C4E59E76AE1227568E0CB2CB0776F6E4E6F705DD923A673036C048B8DD163D5AF44A76C106C42CDD79531613215AF832351C782E4CF0438EB6A51CD96596303B91EF0E70442D1C7E1EFCBD5CBBBA13DC5DBF11FFFC400211101010100030100030003010000000000010011102131412051617181B1F0FFDA0008010111013F10FC5374655ED8B6E8C5FDE12AD2C26481F3F2782B2D36EB093BA260C3B82CE724B4DCB5EAD0CBC1D4067B87D2D5991F97C179D5DDD4FBA484B3AC87575C6708E752F55D935D4EE4748E7649D751E77F8BE4298964BF4B5B62361038CE50753D2511BEDB83F85B1EE48B8597D6CFC85F19B5F1E403094BBB0F61EA2373F928C8EFF6D7A4A1DCC4EB8DDE7C806B23A3808C50FADBCDBAB58E2B753A875A4B1A413064C1E10FC48B7EEC10DF2CC32D5DC666459F6130B4F90216F899D581FB2777EC86F96644450A3906106AC5AC186440CDB4641C641DCA4F73645F6437BC7BD3078E48F6098E41A97FD111F9F23A70CE32C8F20C877C25F440D820F3C3FBFD82C07930E99F83C2EF8D2F3420CFDE4483A20B38FB3CEC36F054FAFF009FFB7FD484EA1EC7E3B2DB11F56D87DF60CEA7CD2DB61E3653C4EAB1629B22E431E7607E4ACEE6CFDA17FF00293B287EC1FB7F27F105685A47ECC1792CB96E3474E5DF848772D310E0DBE176F6F0FA80D90EDEAC9DBA936C30F71FB97AB1FB32B067D83BBEF0BBA9782FB1E92771E5D9EE3CBD71F2FF0013E97DE3FFC4002710010002020202010403010101000000000100112131415161718191A1B1C1D1E1F010F120FFDA0008010000013F10A0B679893259388612F52C7CFF00C592D65806CB9521C25460588D81DCA02B1E6B79857559A61D806446F3CCA735632062B34537A18A8F1D33C441F4D8125AC72D20141FEC114B54EDB4821502D0EE153ADA4D44D0D1A18FAED693BF6CBAB04D076F106E5D63E47735AD3896E3D54B77CC4A1E49CE6161431110B0BF074C2F23630F3536C6EEA64322B2F1E60AB83E88435548E57715C6C29A753630317988E073039B6334028B78A85595CB7F312E002C98AF4473E54E019967DC818B6505D70BEF11B2B0B114519A6EBC4A36393263708352D02FCBC4B5537F3C4CED302C64996B75C441E6AE3A8A04156341181927150B35C964D626C4A64296F7E236C077CF1D424052583923B6C41E8EA0292B7AB80582AA3B75157A1F1058C3C8C5B4996717DCB2AAE5A7438FC4639D6F88866B367A89A0E5659B97B586B270432798799BF21CCCE0CE25DC52AEE5C302AB115CBE051A2547A836B6DF70A6C4E416F0CF88000D39D166E224DF4BAF999035BA19A26245B6618B73054B9BFAD3292D5CAFBF116541215E5B809D0CF32E55DC81CC350BB0A13EF05FC16D9694391DD8C40DF0AA6558AB7106B4C14A8BBA4EBCC32D60F7045E47865E6E5C54D6D163B0DC0B6B5E4AABD42756958DB112816870FB615836952CEBCCA4088BD87FA818A302EDBA8916790562CC106D50F0E70E7ED02FC0C38C5F52D3751782BA894A802D4CDF5141CA742AEBDC00594737E1117B2847A025398CD96F4AD78F713D943A659B2D8364CD5F0625CAC0F739EAE5E21B05B8AF75471DC495C6467C654A116321F7149625E1E2206B2B48F4B97DC32017470BE6343D65B2BB31D9ACC55E08D64D2D5EE54295207078F8221080A8322F771D9832CD64F72D01DFD1CD4697E807086A280E052CA2F45A970916C7F9865639F2EE0AADACAB4C318881859CCB978F98B745189AF997048A66AC3A63AA0B662FFCD4AE0DC670294A787F98303551A7831F994900B5B23FD4CA103732E5AF9B22A58D9CA00F5CA4B515542EF255719B6103C9064BCE0F1994A3026797CC761B30B61314CA649E600D6C098618929981AE9C47C58C9C981A2295A9917FDF78B3AA5A77302EE9BD45975B25111BB81C13EB2EF7389CC44B8B9E18FD615978D67ED2B5CA9E2F9949D80842CD54C4E3303B332E090B623FDE63E722B9E57962A896C3A1AFBBF99428DB16BB0A737AF7994A6C00179079800122F5E0B4E252812C1315FCC01CD8101841CECAF998C2E7BBD78945C19E463580996BE659FE63CC4AC9C147A84D4AD5E3CC60595B95C9035BD45D4D98384E6A3866971BABE6A65436A90C9E3D4BF2C183CBCF7FF930B8416E47C10F2F6BA38B966327B04B605E2EDFA7EE30CCD0DEFA7EBC7503135256B90276E33C4AB446C30BBC19996E12DC0DE880165E8E559DFDA236ACBC05B12E162E28F6412D9525DE096C982F7FF357516FE92F52CA7038EE2E6897D304281B0349141AE39BBF9891328018208A37644E1A114294B0563DC3C8BB879F2CC41C36B79883B062B4CA92533E0969EF86C42F0D1128C71F4453DC0BC2DC05AB0411EF4A89CFA85305DB4A3F3084350C9E2549592AD7E13869BCE7189759737A2A5AC556ABAE19733C12B13897768A0CCBBBB978E8B8A2500B2D5E68E7FA95BA22D1474A382A051B969D1E89A6A34CDBA50DDD62E1DCAEBA87C3AAA89BBE350E591D4A9501E4C96639E626461E4175EDEE16C0D8787353672580983F94D82BA7B95D95AB88ABAE9CE25CE413474625E7C45CB0CBA9706BCCD9AA65EF8A8DBCC65F309CBBD92D3378FC7CC1A8321BA3C088C26F0B2FCCC8506150CF65CA50A187B2241F3DA68EE67820180AB8AD8818401B8FF24CE632F12888A99562B4FF003358AAC05D03880B2CB0BAC6A2B98502B1176CEB8880B17C45C18AC4D82ADECDFA8386DEE01ABCA2F038D7B864F32E8CCD0D15F794E40554ABE5667B6B8872DCAE85C8BF0631132284154448B6E02E67409B7BF505980C271BC8F2CBCCA25337C0FD1FA4A222AEF299D3033204A30A0D0BDD04B16E0456850D73B8DD7624B280A1888F2D14DDCB56E43F0A888A54A1709F462B51EA9B776ABFDA8C06FD6CC6367E3EB065D14312A065E885AD73D4AC40CB332823145E62A61328ECF82171CC4AB56710D6A11BFA9EAAA07AB3C415B97B403AE47F3E6362A19243A7B4ADB48B673A65395D81DCC578581AB9E03909FC4CE0006428DBE6EE5546B098DAABB8DBD57CE82C52BEEA0E68094AEDC986A96A2D9ACD8A56BE11672E0C8E365FEA045B757A7E6658D9E651C0B66F372F57F24A497988A236C8F31D9D475C4C1B8118F54C8F52F069B5CBE63197EC7EE252CB05368EE6631C8D54ADB4A84EF52D0805396B93C7CC3017B22750C31E8B6C0B85F2B2D3520A54E55174B6816E143F539D0ADDBB52BBACAE752E397321B70ECDFEE28A2DFAE820A156C0E83B2F2680CCA671B11DA6C746AC20DC62DAB003C113269C362FCD7FB529EED8D2B1CC307B0F7657EA59658D1F6886AFC20D58D404568891995446DB472E7D118ABD5B13D8361C545AE425E585DE2329A2B34D3E097C0D828F7747274E138604D4CD5B47E40F03E65900F6F49437E84204D99066EF6787C1A801432D7BB6618C8D2D9574B822D9D3853797C70F1160696D6DABE4F55DC24A3A0DB72BACA783EB0E52A050870B03EEF2CA68E51E5947EEE5B4A168761BE180F318DE9BE71FFB364F5655671FE222C3105094527CC58611A7C27001DC1CA4D07E4C4F4EFA73FD42CD47C28B93C404683554EA50A6DB98559C0157FB32BD36280E8F98F66D540186033017467FF252CDCB27F11D61142ACF11D4200E14FA95AA4B21630AAF341CFCC242D307699038A9443CDF53C72F535A5D85A132AD78B63986CA2DA78C075CDC62AD7AD6462D6FA8041CA96A685F7BD416E8EB1F0FF32F164DB76C2E8D2E580DCCD3F041495085532F18FE58593D293DBDDCAC15ACED740F1A8A6AF6B57041C5D302FDC40C32453180C1E6062D225E222F3BEF982B50AD9E25CFCC95DF9980B1A8379D4343C95E3F88384154E5077F7958502B897211345B8482EE5111557547D20F1C7022BCDF43EA56F2B4A05F16D2D732AE46302AE940E01188284D803F99D1C5456591D0F88A350A694BE6BA8A2B183F97FE05F3A5303F99C8E1B5DBED8B0C2287036AF8259952CAE8BF97706103CADCD18A53BD1CFDE06D95039A3157EBF52D2ACD3457128B4B5A1AF5B833AB4AA81BA69995BE80143C9FB9A429F68EDF0F1DCA545C973CC4BC514B871169835A63551B2ACB676710A57983CD7755D45B590A655C679F33BCD2B26DB85B2A36B6D1367BF132916C895BF319890B1CDEF1C38AF2C0A1DB97B74D14FAC718C018581A6BB003F7048B3A255BE3C1188526B981000AEF2717AEFE90EC70E4BE38FEE01AD450A038CBA3E62E0D0AC459FB2F996A343773A7F78C410E4F6D8F24B54E286FCCE4F6E250D48DD301C540486B219D7026364C881737B28E9226FB5D34ABBFB20422A5864B9A5EE2A2AD3BDF9F5296F2B2246776FC869DFEEA5A25840AB0785D6E2A5970B1D8E1088A7201DEE13940ACD6DD64F1EFC46E764BCD1B1ED5C172B13D937ED6FD8165CDC91958746DDA0CA369A3DBAC376F7053A8622F95E7C6E54A86452756D7C1030068367BEFDB0D7B20E5654C8A665281F44B8801BA6D3E621A6A3309D8FB3F32C1D825D978F7E63FE2D0B8A471F586551796B7491D50F66692CBF65C5007088F61EEEE70C542FD8F0425150B3225FDFE59621CE8BD63F10345980306B4FD55006E2D14378AD4AC620B3555CE206CAC308BAFDFD23E906D1681BA67778C9DC5A840C651BB6DC1BE0B9798C2BBB85C1A81977B600661E4952BC466FDC4492E58115BA9512AD39B2AEBF98A5A08E27A082A8216C2DA6F1166569DE6FF00C434094D0E9143E4AF920D70C5AB06CBEC9906353627CFA2522ED00E5D32B56D129844C079CCBFD7271866E794BF71D41DD499BB89488592BB373B024F0A65990E23AAD27C44658ABB55779A962554A1C574F9C90A5263BC29C1E2698DBED7F12AB72D92ABB5D42B1B0EAF96DFC4A1031DD5C3E16AB38976AC9DB3288345657D472EE2F039BF046ADF015B53A8C50E3F0C6E23CA050D72FE980053784C9D445B6598BC3995931E432F04322CD143C994EB846DF81100FA2D5B62D51AC9AA9B18B283BEA2D0C8AC7332CB9ACF9F1001C04CDC01D8BD8EBA8976552E8AB8E3445B6EF7F32EDABB5849CBC323B7F71302040DBD5CD7ADF2ED962A0F9AD4159969F106B602EFA59F2310DB1C4531EE70B60066F30459CDBDA65A032DBAAA7C544A8B0BED61A1C5AEEBF896B89C3792520D1C749302D850F27FDA885C31B62F08F2F98E95B2171088D5630B6FFDCC1C0FA2CB05DF80E23422C00EBA97A0656E8DD7CC0D14DA502038EC798F524C6B2EA12E85CFE889584CA252CAB29E2DF9D468BE8B949E7E202DA6EAB55F31D72A2D365E3E606F2E6A941E25EA568AAAA148CCD34C457CDAEC597FB83782CA1BCCBABEB499AA948C5C16D0C514501A47F52B6E8A6B55FF0090410101347CC32855567C11C47EFB861297C5313388AC39659615F03EA385A3C79886EE995E8BA6E678A3255B03028061BF303756B0D7A80F18D1976A53398C5251037B7FBE63A0D6F20C78848B01C2EBFF0022E30D8AC0777F4E26115ABB80A4B0136CA13AD5F988A9C8B7B47B681546DE9E259628154A061CD339A66BFB800B61814E3C4645B6E537ACF52CA59ED1B2C7F3F987CC54AC39B24D64D40C5941634812EC85A5BC115CAE1738A446AEF77BB888265715188B1F55B854302A155EADD4BB07597730DB76C16D6260936814E0AE31C4C9C21C9B2F88084E53C4B8BB4C4F8EE3B42B63C7FAE100F494A8A75E25980E869E632C6B62D560496656E8D6EE7342C37F6FC4F00FD026EBE200DA0B6BB948B9E06034FBADC05CC708F3C41E543565E59BF90283C4C4229F3D460601A1F446B7028EBA814826397505E1ED44B7B652215630C6D92561C91769489775ABF9A8BD9A8AE80C7E654022A62880FDC0A1DE2A2D77376CD8CBC325E2CDC02B78C05D32D28682906A106C5977D91721483666EF242821EC0BBFEE549D39AA7F339850EF70231DAEE6EC8AA439AFD46947E1E2151CAFE06A08A54D58C05E10B75BC465140DD5DEE6DFA8C3555365AA82105308575C92879051D1732BB536B04A8D04D1AFAEFE912C3205BC1FA887D4D8772882BD2F286F27D22CA90AE6AAF8B3B95C252A2B864316B502A80556E33A898922DDEAE3B342650603889354A0178F13685B2705EE54BAD39B834144AF67FBEB1806B6B2C2C7DA20503C9D240010E54685258FBCD8826700878EF1068072026097054A98B1950CE87054AB07C456D3466EB822C0AAF789A52000AF6E70114A8355D98F67F17111282C38D7F53C993DC2B058C01AA5FD42160048AD2657750F7D3F32BE3DE20DD52BAD87E6104304C14BA27788AC1BE28DC0B4415047133A5ADD376E5874A675E267B6B40B6BC5E2E2B20B15D9199B0FD4310631C2F5A66461BBD67F71D62B8B67C2695A6DBA80EFBDC547C16BCEA241BBD32A2D735BDC6EE2E929987D060336F9F5006BBEE35F31502D55780E09A04B6F89A7077A0897C5951A0E581528C18736C010314BE4FF005CA417765FA896C35D3C020546096DBAD40B7ED5AF88D9AC85F631C05ACEBAF3F69515434AEF319934AA8ADBADCCACD85F5296ED2F106C2A6C2AC96C6C8B8F501C9CDCB2BCDFCA16A99782AD7106DB51DCAA6060EEF309336C57DCFF007328606B66CC310F80E0BDEE29B5D374D6209C9CBCAC1E02C52DC158BC912AC4325788A88AA5578967014D2E3FDCC4C6039038F98954080537345186536E761A992578A7DC764ADD4BC96E196335D3B567708A3CBFA95A72AA13B33299C12C8BA787705917E90036EEAF8CFF001291657C468F98A01CCAA5B78FACB2E9444BA71FED44A0700D1CCA5CEA18C047C85385965D47056DB8DAB3A669AEA5A8CB5AF310586019E2010258D3FCCBB039163F706D26388AC517D4A37CE6E94F84B01825DE48180CA8535700DA8713AA4E4CF94CDAEDC5C670F15976CB0B2F0D357B08C2C246866C3CC0470A065E0009E00DCBE14553B56204C02C5FE7BF8969646B0B97105DA898A07894405EF32C29602979C461AB42F08F3032EED54CB0B8D81A22A0354D58B2525DA939731AB0766C389423B0D0CBA09585B706ED45281B942D63CF333C2271280E4C1FB97076562E5C36181D798072DE517AB8945965B3B97A08D17C04010325C6D806CAA950A6D60F72DCC979A818DB399803687DF8F886186CB8E294AD5EEEDF3043AC66D97A3B97E0A3CA069FCFDA255299B8E664DEE196997698D0CBC232E2D8CCB21081D3A60A52A2EAEA768BCCC9A1604E479954E45BC986A57980BC913967906A1D931FBD0930ABB37D4A7390D58D7F9995B54C252D57EC98AB920776667232ED8319746920C99E78C92A8089656711589B9B847224CAA137134B46078D67AD4B221E4DBFDCA6888E2A0C3A87DC6245266A2DC3D97275387405E2202866AB10563547DE208CE331BE0BE65328145E3B8F45ED68F1DCCC0A5CBDB3059D9F488C0DDD04BCA342B5D19636559C308C7960349BF79960A96DD04101AA2F110D97A5446C55374DC4D55981126E8D354F32B0D0C181B2BE20874526B7310872C7FDDC4CAC055662D3CB2143EB072078013DB34E1763F4711E1137A09E7F84B108E52BED2807819985AE6564694CDFB97816D1BD9EA0620834EDEA3AD3814DF6FEA28493807730EC788E8F3DC374AAA3EAC56953EC659760AA6A616CC83C4771E871286695654F4660288A6AABC18976C3D62610E51F975EC8FF00B812943D9A48182AA9C1E7C204A9528EA2C4EC20372C0F8A1F6397A88D8B00E6B88E35F39E080A7E62A3271C3D9152C32B44F728B28B84F10D2F50594B6BA2589A5AE8458A8EF1FB47AFA03013E83522AB18AC5C028C00DE1EE0D068457BF113752AB206B8F98B06B7B81CAF0C0C169576AE5791C7FF005680B1A655655A817EA2F59ED0AF5B97541BBE4378945350AD106ED96DDA037829659F794150BE0A8230E266D46AF51D0B19834C22383302F50A8C17D35EBCCC023003070C5CAED87A3CCCA30AE1D729530E6BBD00FB3F5FFE69C065716538A7421ADCE45A42805D7881616DAFFC9B787CB1019AE667E2502E73D5470CD6EE66C4D2FD260C2D9C4B117839F1158AF86F714926183B84817EF907B875AD2EBF498ADD078E267AC711122C5C9E6B889BD033B321F47FF846AAA809D44722D6B4BD30016EF550415B4B959534AE9CCB5F8C66595E966625645BBD5712CF263A96E4FAC7D3CCCE4EEBD441E3CC124A72B898486CED476A4BA01DAC3675EA5A269AB582CB30710B40E28A2056359E496710B6379B2652C834727306AA772FD75D4E93825A9E53F12B2145DD6C16A52F27A66472E344CC8DD55218A808A319A9B16AE5C61EE2A7429C7A9686B661582C003B2E20F8F1288E4385F3012CA6B9E6332053299FEA50740567C1FD54CA5974BCCC1794D95769845EB32E9050FA874614A174582CB00066F783EECEC0F6FF00DA12BD93625B08C1E53B08E7E2517D007B9621C9DFD21C180CDB151B73D73304A1BA099DAD65D08152F0EAE6933D28E208B75C1D0F51C7365D31ECF1FC4030DCA2F89585ECD3D12D92B989B15379917333D9020D17910BBE9F8AE605B2D01C7FF24E9A67EB360746BE93538283A9F703ED37F8AA9A1C0ABC4B64E6AF1152D791FCCC4B0E9E239B38F30175048B7016EA62383B4DD72D132B3B9F90FCCD1364D181BF149F24372583415FF3662A551B4FF9FFD9)
INSERT [dbo].[TB_MAE_ArchivoBinario] ([ARCH_Codigo], [ARCH_Binario]) VALUES (1047, 0xFFD8FFE000104A46494600010200000100010000FFED009C50686F746F73686F7020332E30003842494D04040000000000801C026700144770576F79437434585A516E5031515F4B7739341C0228006246424D4430313030306163323033303030303065303730303030313030633030303039313064303030306462306530303030633531323030303065393139303030303961316130303030666531623030303034313164303030303035326130303030FFE2021C4943435F50524F46494C450001010000020C6C636D73021000006D6E74725247422058595A2007DC00010019000300290039616373704150504C0000000000000000000000000000000000000000000000000000F6D6000100000000D32D6C636D7300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000A64657363000000FC0000005E637072740000015C0000000B777470740000016800000014626B70740000017C000000147258595A00000190000000146758595A000001A4000000146258595A000001B80000001472545243000001CC0000004067545243000001CC0000004062545243000001CC0000004064657363000000000000000363320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000074657874000000004642000058595A20000000000000F6D6000100000000D32D58595A20000000000000031600000333000002A458595A200000000000006FA2000038F50000039058595A2000000000000062990000B785000018DA58595A2000000000000024A000000F840000B6CF63757276000000000000001A000000CB01C903630592086B0BF6103F15511B3421F1299032183B92460551775DED6B707A0589B19A7CAC69BF7DD3C3E930FFFFFFDB00430006040506050406060506070706080A100A0A09090A140E0F0C1017141818171416161A1D251F1A1B231C1616202C20232627292A29191F2D302D283025282928FFDB0043010707070A080A130A0A13281A161A2828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828FFC200110800C800C803002200011101021101FFC4001B00000203010101000000000000000000000405020306010700FFC4001A010003010101010000000000000000000002030401050006FFC4001A010003010101010000000000000000000002030401050006FFDA000C03000001110211000001DDC39C9EAE0F7023BE4A93439EA13F779F1AFB28CFDB64E9BBDA46C950D2F42AE364FE217D3711EC5E0BA16C767A616D62CC3E0BD1309A5B9D9E4762C4D1CEF17E8007AF12F38263BAD2F1B1B7586A2694CD8FB432682FDAD18A7613DF47D5B3C2D66C682991F21647575D24540CC36537832D8F5BD763A71A3CE097C115489669B40E06E67CCBDD7CDCFC2207489C9B48AAE212EAED42D93CAF5EA63A7789D6F84DE46934DA166152DFA2D02A724A94E1D35278C7886DB60B7EF97943C14C332FA4C26B7275DD2B24858DC70A13587B735378E8B93517E8123AF2EFF3EDDF973971EBF600CD1D90E9CD67D5F7714C23C4BA448B7960C0B4CE010B9C12F260E45ADF1F5418305D01E89B174429CD321AB108AE7ED9A47948F949E44C7D6763F3513E7DDF0A384F886D3D9539A3216950356815A37AB6AC2044F657A4E9D4A6FF00AAA5A8247E2C5B4C24161ED9C2E1C956C7B2C187C2E3166E9350CA4A9D4FE957154114001098FD1E4AA8D68ED42A53BED87966FF009FD67B218F21127625C3743AF3F4A25C28D1603509832FCE8344F5C19FDA10D9924DED917D338EAE9A6FA4773C95EA3EC70E811954F4D1B9C1EEF9BDA78C539C9A1A512B4BC80860079F48C5E6484D0F1EF4A36B1248E6F42D6D03E8459676C7AB375CAB94E23DD5E6819CD665FB3C1AE5746CE7AD384A537FAAD399D4F2BB4432429FC5B9E66D134349E5908D7072E5ECC72EF45F33F469A9746517A2BB6557CC0CED14AD41306C9CCF6978DDBE6ACE7A98D9DEA70570C789ADA46683AE85EED412AA0605EA9CF0D31FABA2C2076238F342A26C8BD126ADF41DAAECEFC43885AFD7CEF0AF14D7A5D0ECCC5BFCDE6D93763E5E900F14D72A6D18B44AEEAD5592A6F5CB7C4B0EF5510D920D6B220A8B26E8DFEFB17B387B32FA3D4D19F08A94F4E58F1EAAA478F71CE934B3C36AF36C9D38A6A9EBF04E1CC9E28001EAE1A73D5761374FE34D6FE51C6969E8E706D5615BBBE719BD1F3BB32FB9F0B33FD9D2B72418D1588B46B835D0C734DB39353544233B9F3AEA7183B9CC70DBBF3A4DD56B725EAB35EA5883653CC017ADD51FA952553EF7A26A713B883AB1EF662CFFC4002A10000202020202020005050100000000000102000304110512132110310614202232232433344115FFDA0008010000010502F831DB4BCB7FB87F408BF14AF7B2CE9898D8F5F9EEC86EEFD36DC1618AD3E4CFC42BBA91B4DF8746935350CC8FAE687F77FA9671CAA8322C6C8B6E031B19075AF0A92E68415D7F2673BFEAE1562EB3F0DD67C5350896EE739FE4A38336636452F45BF1AF42563D93FB712B095D87F31775F2DFC363EE0F930CFC447FB5E2D5BBF194F83175F04C73EFF1021EF42933F13D63BCC4A7C8D9247947DD7EA567BB64648688DD578EABBB63D62BAFF411394C7F3CE3704D6CA34373621968F7C953E6C4E1FB7E43F118F352253FD2C46FB59D6251B5E87B747D6065781F133EABE03BF9265F72A0C6B57272157404ED373D4B5469D7630875ADD55D32F0145FC810AD17D45F65AD5EAB6CC574DAA5442602034FA58EDD573326FB4FFE6B5E7030D31E6BE367E0423F69DCC63A995EA9CBB3AD3612EDA9ADC75E8257A9C6F195E5F1B8A8D8F6639F75C3396E51BCD8389919B303C94F22A46B7F1EE6CCF667FC6DC57EAD90086E62EED35157D62D3EAF1DDD68DBE36179E258E88B596BD1653F5927AD57F10D659C7AA71D4E0067B3535F1B9F704FF8D18FAFFD3A95AE7197997A9EF8D5F96CCA70263D3EA8C736B57427514EE0AC28EBA95CB86D1EAF6293294E87F46A7D411A72362A25E9A5C03D29753AC1C7FD95D0A5FC62D7A295AEBE83E1A18B1BEB5B0120FBF8D42211353D897585474375BC9A7F6B8CD59295F9998E936C4E1E3AD15884CDC6713B6E24307E9CDE4029D4EA26843A87FA8D5808B9D9D5B2613F4CAC65D2AE2176C7A92A51370B6E1DEAADB4EBA6AC46107DFF00C991955638CBE46CC998F57C6A7496AEA6804CCBDAC8CB0FA3C7DFE4AEBFA1F6C751C80135A69D21B0ACADC4679FF723935A9B2791BAC1B663453B9557E96160235834C76739BA53A844B17D718FFB312DDA29F7F60A822D4B11ABCB6897A3C3A30F4583D9E532BC54AA7AEBEEAA7D535FA459DBD130B4DCE40F682111C4C47F16422F8E21D8A9BE2C5DC7535B9AA9B8363830563BE572019B39358558FE9555EE555EA56B147C18619C80E8A2309D763538CB4353FE221A29D88E9B8D41DF818CE53245718EA96E415F1B08F6C7AD7DD6B1445F8DC26169CAFF00ADA11D7D3A81184C0BFC57280E9E36AE516880FCF2594B8D402585C7F6E42EF0B89C974B51620F4B04D0D684F53F94CF4DE04FB67FA69F538CCFF1C5CBA1A5D6D1AC7E5D1B22FE4AAC7195CF015DD7BE412C042DB6BDC7E4B8D4FDD82DD82C1370FA85BDB6F48BEAE4ED494EC10694C610FD99FC630EF38EC84C247BBF317DCFDDC184C4FE569F236357D130ACEB6083DC0B2D3E87DD6DB18D66A6E6653D5C6F447A33EE6869961F455819E212F41B07E01D4C3AF6FF00C4ABEA71B6F9EBD7C7D8B5650DA837DD41D5C9D946C4FB977A45DF45F52C8F3A6E797D587E0A7F42A5ECD8B5815D8DECBCE1F61FE3AFABD66B6E3DCC73DEBE827238DE3B77327FC60FAD4B5A6B711BC66F20C27E01FD987541F56B6E529D9B8CD3E57C01EB217D5834411AC37EAC1A39046655E2B323F7515E990C61EFACCB520F6860942176C6A48167D3105D075AB8CA16AC7F8A8EA5E368C22BFB24ACAACECACFA198C1C020A63375B08F6468749C96827C26374C6E3B1A7F1197678D3093D5994117816ED83F1688FEEB61EEA5FDBF656C34BB5BB19B6E860DC7C977F9D37D4B6DB5A17DA6EB271583DCDEBF9ACB25516FCC0B29AECC9B2EB419AF36570568B2A9A9FFC400251100020202020201050101000000000000000102110312102104314113142022320551FFDA0008010211013F01E27EF94638544D49FE9110897C13F7C44508CA5D9921ACA8D3AB20BB14D1B2324F677C263AF7CA3E0962DFB4657F0446E24634648457A123E96AAD9369BEBF0446551357267DBBD6CFB797C98969ECCA4536AD1534AE5F83202FEA850AEC7248C99AD9BD92F441EA4E77F87B3A488E55B1B2F92792FA4289082F64E9210CC785CC50847AE11E567A7A909D97B46F88ADBA34944AD88C3BA447141139EBE872E7CC7FBB31E5A3C5C9B2189D0A7666F256285B3C5F336EA67D4FF84A565F1479EAB217F060CAE0EC86453EE0368FA915F27913791908D18737EDA72D9096DD1FE8E16E3B8C8331E6D479648C7914D944DEA88E5A958B2292B4599576425ABB24D495332E278A5AB3D223DB1375D18A15DF1E464EE8478BFC713ED7095A3CBF17EB42D7B455C44E8F1DDC84669E88976463D9892D15711F5C78FEE8CDFAE36D138252E8923C5423349B7656A918FE5987F85C7FFFC40023110002020104020301010000000000000000010211031012213104132022324151FFDA0008010111013F011BA20F8F84DDB148FD31E90E85A48DCE3154425B959BB9A243451154B4685FE08B2445FF000865D9C331AFE8CE49CC8CDBD37D9055AAE4E99B6E45D1ECE4F6232BDFD1891693E494A2F88FC112474AC73E05C8B1D1B5212271B230AF8743E4F53DBC94C8468B1C888F49CD21E6937A4A8F17171B992435B65A5D1699D1299EC6FB1FDBA163247278DF8438D9E4C2991D2A8863F64A8CFE353B89B79211A121B2CF15DC0465C6A6A89436F12158A12662828224CCD8D3FB0B458C78D44F0E74F66B28267AD0D522CEC71B546CA74F4C12E3924AD0A34ED1096F56B5FE937A462519BF5A404374CC3E4AC73A7ACFA190FB0864FF004F492E4466E8C2B764564588C8C6415692327EB4FFC4003610000103020404030703030500000000000100021103211012314120225161133271043042628191B13352A114238283A2C1D1F1FFDA0008010000063F02D703AAD5549EBC57C0357CDB045EFD352880394285E26E785BD8A05556F7E085FE3EE0D47FD300D1E776AA7741BF13D06B741C24A87681A49555CEEB18EB849F320F7D587912042753A9673719C72CA35EA7D15CD906FC2355E37DB8BD5C9F96D5239531971BF05D31FB110A83DAEB3982DB68A9D5883E53849F285034184A01C606E56568E547AA1F39841ADD07153DC3493EAAFF00751C2F1171A2A21FE664B5656032DE6C27AD91C64950D5A26E76D82029BB8798C27817856E283305386B729D2172DB728536E8C1FCE3D940C2FAA160429A660A138495928587559ABFB499ED7599B249117E2B1C0F546A3751728D43FA8FBFA2EE70818F32150CB6A490D7234DDD60F07F4BEC906A6EE3B2AED35F2D6A7B6A0AF06BDB6EDEE4744C00D9E830293866759180AFF5526210634C340B2151C66D089C1D9754FA8DA8D1266213FCD52B54F31013DD51BA99E2D16EB547993B34E602014E737F4C68A1766A006B1F645E76D11CC3935421B0B45189C22501EE72EEE5995791757F33B559B311E8AC26FBEFDD1F67A5B0E63FB5063741EFF7C2752B3D520FA27C65B5D31B69CB74E27AAC89D4FD9EF54F99FF00B565173B9EBEF4D3A1776E7A706A89CDFF008B33A2116526DFF72677308A973CDED6B5965600070DF5E08C7FB8FBF41AACAD1919F952B5E0BA2D1393A7557C01DCF05CAB60485CC38229B731FE179B28E8DC2FC4637B2943091AB351DB87352711F2ECB9D9F6562B623011A22DA4798D89E8A576431D4ADD6A706B42B698B5C34D0A0FA77A47FDB85F09599BE559A0072F39FBACA2FD578741D69CA5DFF4BD082B49E3D7F8575986AFB7D11C27003E1E8BE4FC291C12179A11F66A1FEA1FF847B5D3E85610E2DE5775438B4C691EEBAAB2818438F215AAE5F2F4E173FE3F842CCF32E75C940754CA9B8742CB24B0ECA78EC8FCA5594F41C192B1E5D8AF3B5667546B7BCAF06987BFE643C5913D14D1A664FEE45F59D989C5B4D495076E18995336DC2B27B7A8528FAE1DF83529D9E9C93AB822FAC7E8BB043012805DD0C2D876D93A5DCDB1EB86438666E85475C7D786602318F752E410850756FF0038E4D8A8DE541D7AA07E98108B7A60E3C399A61CA2AD9D8C8C277C59DCF04ACBA117180C3C40390EB87AF0F6E0214C2BF44020B9746EFC0534B7E12BF08B7EA3020E888D8E89DE92A782FC226115A28162ED902DBE6C72BB6C0A81A755986A148C3D1386C8B3BF0364F363E2D459DD85F746ABF4EA8BB7D82F47620B3E14630836C0B0E9B604AC87E8A7AA070CCE44BB00F78F45919FA54BF2A05A15B540BBCA852A5E4FCAF0FE16AA81B66836C7FFC400271001000202020202020203010100000000010011213141516171108191A1B1D1C1F0F120E1FFDA0008010000013F215BD08F90FA8B1A21600B0BDE6D3687C1A7E1B419D456B05E620D85F1DDEE2DF6B9CE6614B07B8A23C6E62B7CB2B112C8B9A826859B2C25DA60DCB9388A70C783029CCB6ADCA3542951F9E3E2F11CA15AADA3FB7C078953C6441CC046639CCDEF6C9E20894007C313E188B7714C60C8FE3BF11AE99E3728D42B56667770683C547295D6C07980D58CFF007F37AAE66D2C12D0A98B9AD875A99CA2DF82709D96EA1358740F9557C349400D80400E4D2DC5EE018722F7734C46C8B59A85AABC92B1FF0030409A1B8292297E5E49CC0CAF24B0C53A226EFC20532E7A085E0031028558B8D496ED79207983128F9498A58B96C97B560FCCB39E7F86A2109F68D9D447701D8971DB37B4B84A353D3894CDB6443381B61C6E582ED3D4C80D542C7FC5C5D05D661511B79C666603AA8D4CF8BD2532B625E25CA661EFB315729BAEA171181EC67D251E08DB88A91461B333343945C7FC86FB80AF67D11678047C22DAE105CCF329B0DBCC30165CBC4AA3C612CB2EB96E4230D1002391E25E202F844AFAB05D66A1ED332925B593F5197D7DCB959326EEBC44257B621F446773C125E1C1102E52D9B041F26E38DE2561EE0BA5B58AEE5ECFEE07AE4896EAB9ABE196D339EE0C4C48CDDD4C01759963EB1B613E49F6EB4E4FB9435AE202106996A7DB0761322C24A97752CD9ED0BC65B3A3B9C09E8E21BA71899AB5041B1D9BF12FD8AE8F2C5A2E0654AD517AADD40D2404344C6137637EE578933822683151C38B8CC5CF610DC18BC17A21921DCCC2BAAA26DA95EE3D123E9F9F82C3304D72A57FCC94AF38A39CCBBEFCEA82AF06CF5386704A961AB9FF00B9512E38FF00965C2A1B2697A81C03C621B9A021C9F1A231B46A3016DD1040BA25799ED9EA50FF00D865FD902D87F52FD918B48443A622B89615A197CB198836E39175292703C31EE665A6C536E63C0E0784002A141A95507FE1A993308D41BFF12FDCFB80EE0FFACE9B8B282D2C30B178E80EE0ADD1C4596B9012F6B1707B9EAE31280F38C4C7138700FF00744176265F6FB622BE0633A17717F0D60E6040A34D4E704E331C33EB7D3CCA566BF114EA346E3B6E7DCBD8BA3FD7715600BB701108AB16D57886E7562FCCA8F9422DEB4C1FE507046A8F8624B1886DA666BC9A97D389612922FA22F087B97C0FB5095EEB37ED1D450317FCA2DE7F728F70439966B02B6F52F58E23F662FB4B9271CCB0AA82E5529F899C30FB99952EB728AAB34B825876184F0F6475540EF338B71A54B177514E885ACAAEE3578B041A2560D989C1A81C4DE27E416728E565664788C5D6DBEC50C29B984FEE151A4444A4DECA60973597320D1A777EC44DB03C31B0548967F4DE65CE9821D4C5D110E28F8DD040AF2A9C593D47BB9F511AC2DFC13471CB172EDC7A4EF11FC4876467CCFF00D3D45B08FA87789469B9B41C887001CEA125628A476BB2E88333953CBD7F6962825A3F7B9684769B15070A94057C77D3FA9C2AFDD4C215AF2F13B5EE3AE52E5982198E271588A2D094234DA1BCCB82A2158CDEE29A80A80F32816BD21744760E7ED302C280F4C66784B4BFC40598C4CB3CDFCB88B87C798E1B7E670D3F9955E1FCC3F82AFA967933B8BD1E65074E255EBB94E8E7F0CC436E628E70D0BA815882546A5EC307CCCB4045CE5661BCA57272DE2BFB861A1A54050733131A82BE16288476B35D92AD431EA685916506695D540CA44FD936DFE3E1B79583F71789A5BBC33454CE89572700C47AB02E85B0BADAF5FB8B0299E8F13E8235BD1443743F99AB60E7A9CCC8B831F0C372DCA5165D0805363D10F3CA52FCE4ADB0788751BED537C98EC96B8835EA423EA50AC5FA9DFABB826EDBDB7A262B0BC759A9AA28A98A314FCE6620FED21B59C1974DD99B3888E25E026DB632CE5B0C685C05384DAFA63783AF246DA8CF8B6F860C8729952ACFA814B4AB85A58BFB304C752D557D9010D90A352F986AA0F8D4C04BB84652B32CB6836EA5E18577CC35FE810A14504AA656715A3C4DD56B1602C8BA6926CED0DA6522AC5E22C265266583D7E66899AC30A02666E28FB9E1529575920E9E5442F48AB67332BFA86DC42CECEE549504FED948B33C32CABEEF10BD6E87E2EA179FB6E19A1685C7F13A3938EE0AFB3E04DDBD3862B998375CAFA9899C428AB87644AA713F67EE588E753C4D0E88BA750F13EB51945CA6141932819BCF32B60E77E251995EC54C4B87530462C89B9646B86238770A95D431EE54C2B08F32A86B3283585393551FE8A5EDB35A88F95C393BDC228AB8D3D4CE692B1C30D31750664FD6E1B0437A9EF7B1544B25F94575BCBB87F64EA73DF53007C2DA801FFC094E9630996569CB97A8DEA69515BAC533AA9936DAE898679260945B528FB378EA2F1F1C377A18D5496E4229E7FE61A285C0088E106FA4C44295E6EA29DAE4AFE61530CA4C877AEA2BDD265BC7102D7D34CEEA4D2DCF3A27338BEA561CE08EE6A6D2A3A857512B178D54A90C97D4A3068E6261BC1E25CBBF790989A9B5F879FF005345504D3FAF12DE10DFA203710ECE5FD45172F2FF002B087A2FA4AF87FFDA000C03000001110211000010406882889CCD8B6D06E0E37D75B122F32D415FF3F838D1727A440C85D3CF5278F61ACC8F4329D842CF6F8DCE68714E885F3850DBD860582084AA5DF5C6682A4DE1FE14D78192A65615AF4504545990BFB5C943EE56F34AEBCBCA7F8E1CC6EE8F8A50B2809DF80DE977C540E0345149590F251D80C0F0E62168A36174EC7E37FFC40022110101010101000300020301010000000001001121311041516171B1D1F08191FFDA0008010211013F10835C8F5F05D397F7D2733FFB1003D652FCBB7FA48DE7C0EC893F5680B66D061661D6124783F11C6E7AEC4B180ECF6DE7A9EDD83F513EECF845D1DDBA0ED1E4005BF30B6C932F19740FFBFE67420BF48F4E250EF8CFECBEF8C269C993B19F15AE4B787235B81CFCF6F1BCB4B2EA66DB064DD8620CB1C209EBC98FD1FE6D1D9429F2F227A72725C39FB0BC5DFAB7EC98DFEED9CB80CB9D8BD327E9481996F2FA5EC0322EDCB427AF436E9F9FE2FE1E5A36E2771274DBF87F37E01D91D8BEA61905247B7C8484469A42F5C9B0587858498DBC666C0960913CF7FDC55D9B3B3AC148CDF4B89F80ED399FA637F74D2344822425C79341F2FA2DF0B83EE3E066FC038B7BE4B4FC7665BDB219147EC3FD4BE5E968E49AC2E4FDBE41E0EAC462260C33E16F5264B76F25FC72607E221E43AFFE5E274ACB8F581BF6792DF83FFFC4001D110101010101000301010000000000000001001121311041516171FFDA0008010111013F107B60D604FCAE17F865A76DFF000213335BFB3E45E66D73665C25C9DE1282E34FC490CFDC30CF82D24DDF906BC5EDC3FAB507BB0E24CF4973B65E162EFC6E5C21EB350080E244878121C6713CC99F3338FD80C569C45E0B2762183C83985EFCE697EA4BC237B067911D66B6E1697B1C6D85FEDB02E07668E42E4FF2C79680C3C95D6476CAADDB235B66292F2107969F23E8C0F8B613FB27EEF63F0D2C2CE593DCC9601F85C24DDBD900E5FA94A9DE18C7F1B7D25A97DB7633076E21E48B919B0A2FBF230B4F2F7494E1C9F2B502AD55F72A8C95C7A8DC9813A46106ECF939EADF93DB96C08E3F818979EDB1B00F061065B0451173C8FECF9CB7D3F7E08E250F71823A1B2DF64C9BE4600B757F973C8F765FFFC4002610010002020201040203010100000000000100112131415161718191A1B1C1D1E1F0F110FFDA0008010000013F101C1546922BD82B954002FD422A6AB9B7501DC0E8B07130FDA60E22E2A62D7E3D60ECC750AD829F99441BF38B8AC2E45D1DCA438E5B7CAFF27E22E967E80542D005DA301711B2B2AE059A1284A562F6633AFB8F6531F26EE6A0AED61579B808172F2BFA8686D80CE7D7DA381C0D1762D6EFC95F12DA532726A53542BF5308A3AB3FDA8F1B616A608A488D04AC5B1E5FFCB6BA817EE97554970D579BCE25818738DD41DC118F1DDF935F132A75E8BFCCCA5D0D81A6878082F8C6A72E93CF30F8367C877BEF6FB4A4E5ABBC007BEA7B4D9AF59B975D4652698EECA0D862CF332C8C574E28F92E273B6F2D80F8975895E30EA5348568A80144ACA6A698B1666EE0E0E461DD7E38805380D62C392F75AF330D34069381E1225E9F52068341895018C0F3055B17BA61E27B771682E7AD3473C6BF32B580A6E8EDEEE52F1236B439A9630095694D6BC402D12B292B0DFB51F3005572F51D377380E20C330575F32EB28F1BEFF5294704B9293F2450252AAD2DB7E712DB6CE1BD4659BAE311F6D5D9B854B8ABA304AFCE7D5D5C95E11FA8486096D14C2403D3A1D013CF398678662AA0968E5E0F788A342146ABD25468B5B4F12962D3A1F2CB750BDC3BAEDF12CDA81735AA0E083E32757E03FDC4A069F1D2196BB2512AB0FE614663713338770B24C0C0028894CA3DF47C308A96DE9687FD7A4A55A31446B945DE6A22C8AE5FF914D18E856A18ACB9D6FE21979073083529BAC4AF0C7D2A3DB6F6428B13EFEA58EA550B470E5D171D05320D757145233495B100A2A010BC52A04B500B4BAD45EC00AD3A8A726CB30E6162061723BE609BA3A872469B803352C812D602DE8BDB31010873953EFF00CC10244A0B9D81E499817DEEEA38CE6765300D2CAE732E14E30E63B001A70B23A1E4029A61315AEDA7A404CCF051B75E18BE11E06817EC2515C782252851DF2C3B0002F8978D6D7795D42B4CE5D3F113EEB1680ED5F4D4C69EAB2EB454A3D030CE4E31092AC85F88B1322405622A03D45C2C504B0A9643CB83E259DD9C40DE7CF989E19EEE58ACD9E94CC2209D20C5AC63BB8C45B971427551BF100C8AED84085907F299A41980A9B1F152BB8374A85FA1412D2126F2B0C238E5EA21B182F50437175792514570C0112832F460F4BBE3B8840831C094ABD0F9884321BA348E8420D600AD70CCFE444A28C7360F0890E1672B896FD114B07276393B8F6A8A889B2576A945B9434C544E05BE2A3B1B6CF487C1E593331B682F1A8C17B98150AAD0C03526DE4AA970D0A0D4EF319CD01B7466DD638805069C003FC31690A7838E2017838BE60826D0AA8703CC7B4B3C1B344386663F1E2059E80E0CF28770819DFA23F134201B4D8CAE7C757128B3DB9DC700592BE814E2BF310172DB25B41F9829F940C6E8B745AE72DC5CA7A009670F7300034155324D3C53B83E00C1EE732D4DDAD1069CAB38126FA6B4DE3EE504A1E07FDB85B0A1BB18F2CC1385820DBBC63E651A8E818A77F2ACA56A1931A72718CC710BFB576735D1BF7208B201690716F9710088300654DF9324D51009A55975E2001B62BA4A0F4822A94D1D4AC20EDC6A50D56F1E600CD52C0D090B81A1A6E9AB1F150B206DB2515B90E6504A4F45CB076784977C3CD302196CEADED35850BCD0CE216A98BC2D1AAA565F30D4160E4193E52D0A2A0A4BB5D78F32D84F2E5D738F8DCC614B996F90F889744AC56A6C7F26322AC08D1B394345EDCCC6E32E5B6E72F3F6BE219B152E971CF99A03D54090A956E1ED9B62E6FDE49501846D55770559507094CD06A21E17CD44558B81B045DE3694E9EC6E7320CBABF8856F76E98C0B7F0EDD64FB8682A38A8E13AFCEE70DB1BC809A851A1857790FB32FF5002645055FAFE2564048459436781E65BBD801F833A1AD1EAC543B6ABB4E7F884132402D5FEA0761420E37B025985B9E2701C54044E1E2125647752DA08714CBA4AC1B7A9A1BF370736E628A3EEE530487C1154060D8CAC285C3282166D3839C79177D5115508B1BD33A206972A723E618BCC9470BFB8B8DC00F39CAF9978F917B614DABCCCA2D401057938886BE66152AC55059A3B8C12D90F4CD42F00D78EE5415E262B8AA822B630825396095AC65A3989F918177B71EF183434B7C8FD428FD4ADE6C96043BC778808ABAE93BB97499828DF77CD40E89651C7699555956E58FE094F2B472E2172A5883849606D04F489AAAC07A1C4D0F253701D34A03B58317DF4D04A36F95DC0CF71456E3834D6D18582046D4FF001416D2B86F732E834D5C0C4C9DF9996C7B4D86CED6F1020B8DDA1674BB60239B079AED9662993FBF484A03B1082A28898AA6A3076AC9FE25D0B9556A06CD8B3750C88CA94C547696868ADB068079BF8995AA43860A32A2F71ED9832B9523B82A9A2F169BF04ADCB34143172E5E1766760EBDA253C2D6C3FB94C2B1C9C9EBD4CD10C082A220BFDE08E9B0D3B58D45A91C07851899A02AD632542D567DE61DAAA3160E0BDC2807279948598D1078066A5B6100FEA5082C3801736E6A5360A3B8D54B15A00DB5E09540D03266BFBDFBCB5859AC6882A0DE0ACD40B02F6CB1776731434161729FE4C7C4BD222F2EA655F7706C3237B8401D6A66F23E4339A9896337515E92BF34A2B0F8E62CA0ACD4EE6556F4A3C97B7AB8824E6F8E8AEF7F7320007382EB771C70570DD2C2401383C4BC643AB9A33EA543205AD53AB0A0952E916FF315B6D74B61086AABDA28E7A3D282FE5506601C8FE612775DDC74D852973E7F52800B6504280E4BE13D2E0439D01B7D7A46A14F34DCC89686620EBA77105079208B00785C700E5EAD7AC4117BB253939AA5F88B5C9AEA20F1046BD12E325F6B2BA9781602F37A6540A782F3EB01C8172AAC6A007EA137976D5BEA635782B160F21AC3683467AB2B6674F2A966EFB7B477D19C60CF9EA594C9461B56BDE55368F15C0080F923EA400C1C69FB8C00C7041BFD450849BCAD3C136F98AC9AF114162771594A8BBC4A5D564CE1DA744BA0EA99C856516A5181E065F9587E71F516BF0258793A65EBE18E258250DA061A94BC9E92C4DB9E1BB86738D730005B6C3B219E385F08D52D695D1757F0C0AD00D0B97885F2C15B55E22030FE98FF009029ABF2798EC0B01AD4A4AD6F09D7A4629C29AB1205A12E127DB996046DA14066CEBCCC28018877572F7485D50F01B7D3112896571768704A42AD1453A9A5FE6206292885F26D659A814E0AB11AE8A0775A8A0AA2CDD44E2E89FC0669150A5C6A0233954AAF30B56CD50F63CCA502D91225C4E031758FB9415332B63E48AB61F6275F705D9B07A0EA1784B5E218E96E6FCC01B011ADCAB32DD3659CB950AB2BD25AFF00022559474444C7B6F01A3D0845C50144B02F9C328B6F38AEE528C8423C4DBCE8140704346080A5A1CD9D4A5B0A1517082E89565730260AF2BA8D5D4F5A96C0446C2FACCB77806D1D1F38A9A6D628AAAF696368BCEEFA5946D0DF9946B9347CCFB42D2944B81F37A8D55919FC98080B5AFDCACC2936B8AE0975562F588A380AA2F55E63B2346B24078D593B8C41B12687AC42AB73CA51D8412BCC56DDBD17C411616F3CB0A08379197C544A2355634BEA740355FB93D3004B707C46F2DD486ADBABFC44A66B03615DFB73EB1ED7024F093CCA49928191BFC6A04ACD9F5178850E352B8A34109E08918AFA3895A96569D1C7BC61160AB72C424571E1E7DE0BC005DB8DCC8A7F5CD28566017C9099674B1E64A72896A837324296C06D34B1B2E9F8629092F292BD55CCBE3D2164604E10B96C59A145BAC56B704E3821C536A4A0E2DF2CAFABA96E0562C5EE08E0AB9319E1F9FCC2D52078C8B9AF563F31D0A7217AB1E3FDA8EAA5C9EB063217F312D61DD78E9F5EE06A946028447ABF3197CE03B3A4A0006C596C2A4519B5135F06F1B6E092296B4E21DB0E58E7294231D959A85CF74A962F6E22379A25605B6BE0EAC9AC1C0550573533110CABB3F880D016618EDEC4581DE061358F5589BE438CE1817D7DC0AC0D07D18EA1E5F11364A45B17DE6105018EEB4CFD45283C8E31CD406D45F307B0682C0CB01428CD97AF6D42115192AECC78A811176165B94505530FA8F505AADFDCAF43B1F4EA275AAD4309FCC4343FC22159367960BA68B78A879E71A6F3E60D012E9DA9E5EA663E296F11EC8B606EB96FE0884ECEDEB15ED001BA3D8817651D44BB48E874C30A580BF79637A52130B558C2324ECC11C7FBB9586B01783963DA1840714DD453ACAD4B80212AD692CA0DED5559F88940C4142DB043676F50314F477FD4B32A015652F995B0BB058B9FC84A97831B10CA3A96C25C1B4DE83B7F11150A2C686574A4145F2E2125AE6B2731DDA399FA4A95DD2B5DBC19622E21B3A1AFC97E621BB662C633310F7B77CC7C9B96E06EC35772A60D91CAF7871165F254CA7FC209758F49E31F52CB9B16785C9EA41CA6850B5332046CCDF5ED2E18AADB775F994D841B015535F819643D40B9886E977FEE66E9941A671DC67AAA8740D12C94EC63BA02658F3E657F742791F35A7BC115EB35598B2FDF16BBC25EE15C64B9C198BC9FE9160D56D009B5C6BEA51A0C6B74ABF7A964DBE84129BF99FFD9)
INSERT [dbo].[TB_MAE_ArchivoBinario] ([ARCH_Codigo], [ARCH_Binario]) VALUES (1048, 0xFFD8FFE000104A46494600010200000100010000FFED009C50686F746F73686F7020332E30003842494D04040000000000801C026700142D4E63744F304D7671736235326269456C5379541C0228006246424D4430313030306163303033303030306335303630303030306530633030303066643063303030303136306530303030613831333030303036353162303030303137316330303030336331643030303036663165303030303333326230303030FFE2021C4943435F50524F46494C450001010000020C6C636D73021000006D6E74725247422058595A2007DC00010019000300290039616373704150504C0000000000000000000000000000000000000000000000000000F6D6000100000000D32D6C636D7300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000A64657363000000FC0000005E637072740000015C0000000B777470740000016800000014626B70740000017C000000147258595A00000190000000146758595A000001A4000000146258595A000001B80000001472545243000001CC0000004067545243000001CC0000004062545243000001CC0000004064657363000000000000000363320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000074657874000000004642000058595A20000000000000F6D6000100000000D32D58595A20000000000000031600000333000002A458595A200000000000006FA2000038F50000039058595A2000000000000062990000B785000018DA58595A2000000000000024A000000F840000B6CF63757276000000000000001A000000CB01C903630592086B0BF6103F15511B3421F1299032183B92460551775DED6B707A0589B19A7CAC69BF7DD3C3E930FFFFFFDB00430006040506050406060506070706080A100A0A09090A140E0F0C1017141818171416161A1D251F1A1B231C1616202C20232627292A29191F2D302D283025282928FFDB0043010707070A080A130A0A13281A161A2828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828FFC200110800C800C803002200011101021101FFC4001B00000105010100000000000000000000000501020304060007FFC400190100030101010000000000000000000000000102030405FFC400190100030101010000000000000000000000000102030405FFDA000C03000001110211000001AADE62BB85013F3AD9AC52E1D2D7F3812C579B7E6EBF41F4A0889340558B73402DC49F0E95130F0076EFBA5D0A84D47412F24BF3B8DF1F660AF89D17B7B1459CFB155056C64DE0945A0406A075C049D45D51333926942148BA87620E422634CBB43D95571C2A61E0E3733BB0E722AADB13CF4FCBA905A7574928D1B0B9D04A117366A3AB0B6625177653E1742D5D8D1AE5FC365CEA66578E3496C0576958D6A47DBCF34D59037EDF3B752F519FCAEFDE5EA43C116CBA1FD1491A2C48FCD8D2333607C53B12B6956044B5E650657656A9EB6FA88A3474982D35A89212D311AA52CCE99E793835CEB6BF23A11E9E95AC2E3A690B79EDC2BD09A14FE0EAD5BD48DA9C43835E5A4BD864BCBD16D79D1646AE983BCD4989D703A6E256728A2F5A0F3145EC51AD776B7B80F4AE9E3CB89201A88A4AACE7E992FD22D9D123197B59826DC904D5564D14B606D0D3726CAE07557CE16D57BB5BC610DD6963E66C8E5F44A579A574E336C08F6871CAE78682A6649072F51235B52A078D3B4F3D29C452BC89721962C5D829AEACF355A9CCDBA19E946ABD62C32AF2C71A12A83456DCC792A6BB48C4C8DD3E750D3A356A742A3224AFD1722D7966A12CF7559B2B246B337F9F5CC5A0A5FD1E2B6D1A472DA2B2C59D515C112AB0A275F1DED366C8CD0DD081D343CE8C58F4992F0E7868867108A192C576690C380C1317CC4815AC409B67A11668E657919088C9B2598F46C25E629258F78BF2B628A7180A4D3CF277692B3C36C57348FC8C3D64C3D62848A54B9573158E6BFA45F45F373D0E10BE818B02C3A5D723CEE0B50ED37EBCF593E223AC0C5AAF54C87C46BE6A0CCC7A2A923913605244570D17B93EE7351C8FE0D95303A5CAB29EB7E45BB165C37A379ED296A5FA3A0B2C4F0A8AAF68FD09062736D04D248735798BCAD0EE5E6397BA5B57B86F282ACA2BE933E664DA61B72031AC950223FAA179ED0824648D588FAF267729A2CE25CE6B9888BC52AAA87FFFC4002C100002020201030304010403000000000001020003041211051321102231142032332315243034354142FFDA0008010000010502E67312C6595E64041AFCC5F93C4AD104D0F158F75BEFAF83A72B1FF2ED46FC68AB649C7F703F30C76F9378669DB7B07D98E39C6FFCFC13E481EE0CD078F407DBC085032A7B6BD440385021038D793B9D3CE84F10FCC3E80CC66AD3136A8CF6F0A04D26849ED99DB6810CD4CD4F1C78E3CF1E024D0EC53C149AC2BE0AF930FAE226D89DA5108576B68AF4FA64D0D14C1426AD5786AEEE529F148BAC96ADB5D7525CD321EEAEC46C82F6DB786AACC82FF517F1F55913EA2C33EA2F2D0FAF4FF38CF5A9622902DB2A20E42736DE0C5BC72C13546D8222B41ABA25215AE5D1697DE3D7A86D200A4F65A1C668B4B41590E61F5C4A9CD1F4D73AB61796C2B40AB1589145B129B0C01E56AD2B2DB238E7CF2FDCB68C7AF5B4F96BD399EE13EA5B5398D0E6B106CF3CCE60304C2CDA69C5FEA548146654591AB6849359D9620B254969885AC773D885DEC98DB182B704015BB334E7F8EF7E55A9F08A3B36A555B578CCE4FA086C9B4DA069464BD271BABF9C7BDDE87D8D6AEDB0B761EEB62270A8BDB0D95C21242FD43C3F8F6AC48E4EBDB5AE875FA7B3722BBCAB5B9D6D26A3E60533B66146F4E6033A7E49B9421E2DAD96C163ECA76AFC242D5F20333AFBAECAB16AB5B2D40B3A83E985935F66BB68BD6CAC13DADA8D175C93B5A073026A041F1663EC4E3342A54F49522ECCBC534DB73D8C1CCAB26CA8E3F530E9DDACBD9903B46EED9C9D99D9A733694653D0F666FF0032655FDE0788DF9E153BBE535687B89CA10DE8B32566154894F5AF20E38D0D40108B2F4D0517772E501259AD8B90A6EBDB1AB40D524EDAC7A10875D0F4BB0D94294E69C7EED991414AC85E7443023D4C6DD47D5C5B05E5B89D4EDEF1C8BDAB297ED1B23535F392E71463E5B0B8DC991BD68E8AEF7A396713748181992015C3BFB375962DD311071914852D589C4A89AE3B446331CAF73332AFDF1396AEFE1996B96560BD4359710664701B24B56D947620F10B169E223859632B271EE43F50A5B50CFB42071B9240259C78015A6882A5AC64362558EB8573F13B964EE12CA1CD66C7A2AC97D52B21E8C8495207B32079D810B56D2C50B5E25005A3728E7C298C79847314329D9F943FC9BCCB7C5618E7BB7E7A9AEEE4CAC6D654882FBDADB2F4C86B56AA5D9F22D3058E0779E23F051FC59C30C5F632D8F6DDF3104B3612A42E3E9EE96ED5C5F2D96FC01F382DC67754A3BCC6BE0F4AC5E1FA87FBC97BA8C7CAED312C65EC1820513D9C37E4B1CF8ACF0D8760AF21FF008EC43187338E22DA673B13C2CB5F7798BFEC753CE3CF7AD79D36E7A1BA9FFC84128C86AA5D7D16875F21671CC0C44C702B457EE5F3F7D296EA55837A0513E264DDB7AE179B724014E101BA91C39E5FD17C95E04C8A7FB55E44457B2263D742656435F603E98F676ECC8C6DC70C843CDE36331C1B2BE3D70BF667379C3FDA0F0C7E7D16535B58D9EF563D756350D8C802CCEBFB8FF674CBB90D42999D5555AD6F529C8B16FE92C43061C1983F9E67EEC4FDA4FD958981536363DEFB59D2ACE69CFBF44FB6A735BE3582CAFAA977C89D25FDD9941C6C93E983F965FEEC7FD8C7DBE88393818FDFBFACE513654BB5A8A29AED7363FA71F674CBF57BE9EE0C8A4D67A67FBBD6B17BB4C330FC1C8FDD8FFB2CFC3D2BF001FE9D804927A563ED3AA5FB3CF9FBF0B27BF4F524D8567470C2DAFA963F632584C51EEB7F653F9DDF104E995A9BB3325B2AF452EF90C30F13FEFF00C14586AB6F616533A25BCE1F55A3BF8E662FCB7E55FE577A2C36E9802747AFF933AEEEDC7FC226259C471C3F436F7CEA78BD9B69F10CAFE6CF983E19B635A177CB231B13EEFFC40023110002020104020301010000000000000000010211120310132120313041516171FFDA0008010211013F01DA0BA1E9A6CD4D2FC1682388C28C4C4C0E338FF764216434CECC9999916C4D99333DF2E873FB390CCCE8CDFA1C9B1498A6CE4672FF003C387AA23A4AED0F4FF0E3E8C11C6FEC5A638F568A303512F6256718E3469BEE8734475368DD3744A5464290E44DD8A4298E489C2E7669C1C57645D0B531764B59CD9FE9D138ADAED18D98A25A64D626568B44DD946238B477438B447D0BD0B6D576FC16F6460A4AC426449C9446EF643D9163744751C76465449DEEBC2CBDD0FE5BB223F917B1FC3FFFC4002411000202010403010003010000000000000001021112031013212031514104324261FFDA0008010111013F01650E542D421A9F47AD67323910F50E51EA1C8720F6F6C9631745C4B4623D3A388E3438230311A3125FC7B96498B47EB3811C060383FA25F4689465FE44B53F4C764C491D19519A32ECB2C6CBDAC8BB2CCC4ECD483C6C8424C9690D35B256628C4C50951451063D4B851C8B1489F6636A8E21D9D91931A1FB2E8B14884AF67643FE96646475665B7E8DEDA6BA192742FA36F764F52517D0D0D0D918E4CF4364FE086B665644F4B2D9CA8F669EDFA3F7BFB1AB12ADF515A34E57D0DE3211FA3D9B3D0BC71C59ABEAC84AD7823DF9327FD4D37DF83E85E1FFC40037100001030203070301060505000000000001000211213103124110132022325161427181A104233033629114245272B143C1D1E1F1FFDA0008010000063F02D9CAE217DE09F2103E975544FC95D223CAA0539ABD951AD2B31A468A81174C3575184D85728AE69D8686CB339AE3A511FE5DE7E555B97C14C0C126509C3C83BCF0E1110ABFF88D3E54FD51EDDF64770BC28560AA9ADBC2B05FA7B2D3603DBB2CDF45985548A8FF000A8794EBC385BC7E590A77CD5271595B2ABF0CF6AABB09F75345656D174AB21456562AC76D941955955990A6B4E161C99A8B365153441A45AC11E588E995349F7557381520E2478437588EF93742AFA093050FE63127DD19C57344D148FB449B2FCF84D6B7109F851BC4631173E2507843EF2A4C59750BF6421C64F84035DF4E1680E841D310A5C466D2AA0B82B850C0D84E04D172C4A3032D7F7577556A00A4299B22F2E593D475557954780AB880F8570AA73225DCBD948EAE16963A35AA043E7E5346BA942DEC8EF39444AA34A24360B42A82A742AB49D15C2ED0A0441B20ECE23FDD1334350B0803E651C4119655D68A0809A63FEF870C6238671A286CDD4B5E23CA20384F8541245C219232394978EC14FA742B2DC81A8467A9F5521D005E9650F338075503A3BA00662056130E4E5BAAD7D9406882688E5265398D8337250DD739B28718EDB6AA9C12C35477AD971D502E6DCEA8B8C8EC84B88D3DD08A3B550D398B4286B62D213DA1D4CD45CC345203026CC4144304B89D4A0FA40A415470CBAAE57876B2A1D52E6CA198C72DFCACAD0032F50B2B7058D77F50FC0DD384E8D465C5C27F741EE7B6197F3EC9CF25B55C8439F1559A5D6598453EAA5F4C365D39A3A7AAAB0E456735D380EA95011CD01DACEA860B99575A1063A3C78593D5741C40CE4732745B87976415FDCB3369146FBA97192AEB94C26B310566E8BB97B1F0516C077716941D9419A4292DA704B2E8BB05C79ABCFA15CB770B2CD95ED2F34EE9DEEAB65132AEA9B414C9003E161A9DAD736F29ED67AABF29AEC6D69545AC6D5B441B19313D4159595B6551EE292B97172B40A8BA395CC001F515184F62A95CAE0B9A8A55931BAE6408ECB0844548595A6005CCA81318692E89591AF6C4753916434327BD539AC2E6E4A49D56262BDE2A6172B954ABAA1D82A72EAB365824D517917A2CCDA78D8204429D510E683499847907EC9AF1F76E1AA8793512135C6C35D9985B60F7D131ECFBC3D1509B8C48240886BA92B7951498F284DC8980A9B7FE1483B2D0D080161B2AA1AAA811A2B27128BF131377A23819E5C39E6C8ABAADD53A66BDD39BBB6B60D0774DE515B764462E275F74096CF90A0031AACD080D078420234584E3553898619E6DB7C2A2BAEDB0D01F7559CDFA16160873B23DC2653C763B71B04E3647830335962B9E098A5161E16EF3BFCA7BC0C2745323CC6CA2F1B6A84D75F64E71A98DBCAB95C10E506573B6EA506ECC03FA948EA441A2DE620B582C7FEE513CBD91731A331115448CD966AA8B99DF0B5E0198FB269758D0A2DEDC1D65731944A27630F659703E5CA26A506E219C23F458FEFB62EDEC9A37791C3D5DF87F88FB4748E96FF5159DD7267603EB6F1651B4FB6C33D9452112783B9583882E66764342DE63998527A45876DB3A6AB3E1F07F104DCD1AA47006AF84782974D66189738C04CFB2417EEC55DE53312A4BABB328E91C390E8A6103D04E8A4F3F8588EC3D04C765236BB67C23C27ED2473BA8C9D0271F29CC3A1A2CADEA3C41C3441C2C5663D166EC7334750F94EC23F1B5E8EC3C01BE8157ADCB0D05D341B4A2F34A22E3C7BA71E575BDD11AECC207530B78D1CECDA5397C23B7CA9FF59FFE549BA38AED28D5BA6D875793F8307F35BF5523B4A6B85C194D7B7A5C2518E97546D77BF09C4C4FCBC2128BCDBD23B20D6DCA0D6DEC157F043DB709AF6D91594FA4C2E5EA6D46C28F08C31D4F749F6D8EC570A34511EC3F0CE1BACE4562B3C4EC2F6F43BE889E22F22960106B6E50C267B71FFFC400271001000202030002020202030100000000010011213141516110718191B1C1A1E120F0F1D1FFDA0008010000013F21867F9708E154BB69829BD4E25740ACFA4C157A7954583852F38805D14DCD4C0BD7F1364A2B0E62B82E159431DB589836726A5DB0D43476C6E3BD4CD40297C83B5A347897707341658C4A5C65899BD71D91CE804A9881D918B060CDE806DE25E6DD1DAFE951396E46C650D617A7D4D8F3AF7086FEBB8ED7C1B22E1320CFB2DB2A8E2B9993816AAA25A07D620B5C33B7997DFD5A815D0406B264F5082C31AC4301072F52EA3350B94F5E4B86776748ED16647A47E03F0536E51739C0D6E53C076295736F7BA26415514B09B678A730C3864A5B9B0F2BB992D8CDFDC3137E5A85369C92EED99F4236FC848D841FA6509AF251423051E1259C0B56125B41D822D517C3114708404ABB0BD665443154E2E2AB4B97352857A6D2DCA4FEBFF5852E8B743321F5B552CE2B820081DC843BDC4B4831ACC8F51821104E474338E662DBDAC2CCE1CD404D4D6A212825BE53421E31510C3C08A755C08C4A9C54E368BF1350657B31BD335EA55451AB2B722BD45D8FF128529D07E255B16E5E2508EB54EE53F2ECCEA062329BC9F62460ED374274EB00E6E07B0FEDCB970A76161E017E46ABE8E1DE828ED975E0FA8AC9233F51000A3925E200D237717C0842817C29CEA22215AA230952BE113335E0E4834AA76F7888D83B3515A82C1CC0FF004251107A625AA1EE12D305E57FC42EA9A6D79A21A2BDA59988066BF0A97496E2B7E400214DBC90BD4856DDDC2D34A387706EFF0048C11254B4518CFC0C6097EA55143DEB316DD8DF5A9573586F4C60F26C54736E1D9996C6050B8FACE8A69FA8F617B5F9AF61E756174151565A28F02456B2AA9A2346B4AE2BF72B0B4C07827D1BE1FB94EC54D38EA6F741832C5C4EA0AE6F9869E947AA812031DD1F26DB82C5C5F72EF9864CB5F51B880F89B5EE1F04E98FDA368868D44D14A9498BC08F0A9421302F1EBF885B0F25E0991A0956606153CD84CC723BDA19CBAB3ADACB70326FFEE627816103B8EB0153A3FD40856CAEAECF60A876507714D66C37C0465A2A49FD430FD9F3BE9394E9767FA94845286AFB9E910621D3045D3326E11C9055A0557FCC311BAEB6EBEA737315AB5DC354B414CD54C530A756219B99FF00F272C4201FE117F1CF58952C00A1C98B19F6A690A2769D4BD629D10AB7B94ADF518FDD56F5CCAFFBAE516468AC1314710B9FBA42E0DAADB172E012B0498B28C643080D4E424E6B42AFC9581585FCA347A72C0E0552F08B739AB47A80A5AF254AEBC8D9482A17F725C1D4B48E25C76C5DC292E9D22ADE21A92681FAA01E400C2F5AA8C1DA00DFD3C99A7A94EE036B31F60CC80328EF1035884351D43A701788401A552208AD4D322B61088D087A187266C1B96D34B7565D7A1E2A07DA35C65732925BD609C479A2BA298F5C19A980728B0A6766CBA8E0C806981739D312AF59DD5EE255C3473E42B5983181F0E0C1D457103AB5086C6D2FDDC7A5E15444833319FB662A02A22F11D7915EA6142B1907B88D7E618D6FB15DD19A9BCD0B02ED66B0626E1233E84D57A9703207DCA104C56710E7E3352DEAE5B5DF3A96C5E87AC57C486E0D4A86AA29C6DA7BFA80446A1AC3CD4A636B4FBE2156A558316AE628D30EB31DB87B3C080E4F482EE894145BA159B3FCFB82A2680C1195D8ACCDEE28865031AFDB332A093231DAEE69E2019C141286185B47F764E584881198C8587C9E50D06608818165FE08F8CF35CB88D773043187501EF7DA0C6B6031C33C4409B245E7F79CF71889944D629E47DC3994CB9E25230029E69520396F5D4106A70D4F4768F53824BB560460F708B73B4E1F222A4BB2967ECE65B84D8C775C373CC98027F315148095ABE732A59C0C1A5CA5323C531A849059A8A1FF00542EC524520EEB1011F7207DF117EF8F603C655E9AD76FC440BD55A1F5F50E271331B9CA4B3FA7728CE25D04315BCE8F11DF783D1163066107D7EE0FB2AD5403EA3988C681510F52A380EF2FC5E7060E101FE666C21A49434376FE624BBB4C9B7B751F5140D87B371CB5B96018EF19E20B7DCB6335262D72C7DEDC0EA7F49D4CC9DDB0F64BD97216D8D40870455A95EE504C1B9D5AEA5C781CAE19706DFEA1B3ADBE6370652BCA285628951B515EA00B9C0DFE502C2CA3D83399C84FB9DD0FF72D4BC4D6EAA7D8D93E150BA96A286D973879F9001DE92AD11234A54D46696DEDF8B81C1055890383AFD30CB19311D3F2A77C157134AF071894B18A5C9880A6DEE1CB11F98759D419471DC2BE9F939BD189E78CC36A370E2649F7E71F498CE61ECB74314D40400A96EA0B82A3DFE7FDB186E3F16CF9D3D26105BE25F3B9542EE66EF9957F6CC05A4B9A1D4FD8826A35F02DBA27079318507D3E4333FF00585B03FE47F98CE2B76B6276BBE8CFFC2995F07CEC155C73B0442080A3C84A1B93A5E132A8197D90DC6629E132FAC8E927040BFCFF00805DE73DE75F9862916BFC40654B27C82B84B5744D84B1C407E1F5195354369E2094210E312AA145C6305AE8E48E4873116F9A8EDFD9FE4531CDF04197968992656FFEBC88D55657B80C762A3B6653B7B5F06D7C7CD724254312EF439F1DC0A8DC9F5343F1160B10FCCA28FF00B75314C99937AF85E95F033312D63F7C4C409C74A1AD6F4458F124DB656BB8E5845A87C7B0CFC36B93F7E4FF004768E11EC4DD5FF86E5AA2FF003D34825FE7431C3E0E6E501A52F8F807041F6625678C8A18F87738F937F2C89D7E32A7ECAFB80CB89B1767AEA1836CCB6BD4B52FE056531704F3750B7B7A222A5D65DBCB181CFC3F013FFFDA000C03000001110211000010005A133E912B8588A58EDDD725E5D0C19CEEC60FA430C66B7240B36C392626F0BC5D08FD1DBD28FF00DB9CC156B571BD4987D9D780E21732B41383310C872956EF55E6BFEBBACB98A779775F92365F862305540220022F8E15E96A9C8592805B740BC6FD853A759B7B98CD640E4E177BC0FDEC4D65D4ADA3A19F5D7C27B25203FFC40022110101010101010100010403000000000001001121314110512061718191A1C1FFDA0008010211013F10863476F29313D47B6C7D94B0B867BB5F25BCD839D7FD4328A1A325B8C9F6F3B3FC509F96B7C9D61C692BC48F6DC8730FEC84F96BC843970BEC3E49762BBB1967FE41398FF8B3B25AC1EAB9F9C2FAB92FAF969FE6FE0C87A4620DCBB9566C9EDBAC24B3E944C60FE21DEA2FFB83461F09965A231D6E9C97DD8709F71BEC8B246C8035B047911C8C3D76DFA90696B001830DB0B461500230C8D01E5EB0ECADC26320110ECBC4B21DEB2E4323F089788431D855E4A9D8096F8CBB1E63F8136D1AC1CDB7EDEA1946B96280CCBEDD4785A3F3797898B72399D5B33F90C63A4DBC8796F7F1EB67E723F38637AC8E37CBE5F67F52C7FA3C23B2723CFD7D8FDFFFC4001D110101010101010101010100000000000001001121314110205161FFDA0008010111013F101C9132C9434877A956B38664A1A429C82190FB04F96BE10E4D820D80BED879B3AE177F65E1671F6C7D91E4E6DDA46E4E272153A32CEC81D1C98CF2307511964EA173096BFD9E5837A597D1ECE689CB53B263DCFF009FC4466FE09B761399459252C791AA984D97A45CCDD8477F25C01D87925BEC9C92C8BA02C78908BD8CDD3097E6338DD2F4097C5A4ED9CFCCE8C03BB0CD7D49F5B19D80CAA63E4BAECF7161CB6CF57166D8AE267289C80CEC67C8636601F828EC5260400C2E99618302D3D902E234FF0090BDD9E993BC60CE84B9FB30F260D48B21185CFCEA1089C47ECA2FAFCF91283F0FF0F49E4389951EEDF6523DD9756DB0FE8E475C8108BED970E5E7F8FFC4002610010002020202020203010101000000000100112131415161718191A1B1C1D1F010E1F1FFDA0008010000013F105BB632ED731D1F1E61F5376B7F50D3F886BBC8B4EF8941B1A64376AC3BF64AA0964D68DBE7C4C02B86CAA3A798B33AB385D771B970BF02BD4CB28D8019C8A6BE65E3F20650DC4F6FDCB5EC8A5A879567F71563379EFE21BE1CA555FAAEAA16DA6F598DB7555D07F1B9476DD05DE22B0C18F2EE2E14D951AF8A80257050A73798666CA1710350845A4BEF10708CD569E26F7A9D5342FD7FC985D68AE37CC4063D42AB6BD102C634B1DD650F71415317D0B301FA8166E21394F245D8264B01876440C86DB2A8F5E65192F91B0ECFB8E4B84BABA5C37CD160A6B70E8C46916338970CB6876F3F70CAD2B61C35994E81680AB6535A402B47AA881B216402F5282BAA7230D4B475A54B5899C36C5F8BFEDC77096B451B8AC152DE4701044E660250CB9E17C0BAE20CC80A880C18FA81AC35944368698A6E81C017F3A96B08B438AD567DC1E21B95D9A87D9532D47012D301A5B656E5964D566DA408C7940E73DC68587FF085626DED832C0ABD61993AA9506D942A26B055F3035489414A0EEA2D813340D544C9AAEA64F758942A860345F3C5C5A69282DF88DA52A530D7589C957058AA8E6A3D5C09F7D1BC2DAFEA6A09EB494FE73B8C051A0CD4506EB99D3FD06F4DF8B8B4166569D34872F136638BE3F3F3014112CA2B75E225CED142EDFAA868D6DAD1B6AF332779ACA1AC9140C32EA97AEFD4C6EB02A95DF313549406C9F2AC4BCB956336B34609490CF059B35162A510363759C6A609B14253AC73113A021A1E56B1064670A1CD758892C6CA42E2DE08DFFBE85B5B82045E6724EC2117AC2D96DE38B8E80940AAADDFB8FDF60324D81E62B100196268E97CCBB4842A14515BAEF1F72C4FE55852BA8D5560A8BC12A241A010052E2F238B15562A9921BBB0599A03AE7EE30289766C342B1458CE1C747E08249A068DAF12F0AA94AA1B0AEA530C1563FD9A98FCD50C72FBA861B114BC0FF53686740A8C0DAA5B478045D1D560C32C0FAB1015C7504BBA6203B990575A87B21E50B4390E8F344AD9FA829E71E213478C4365C2F4F1D5D412985A1666EFE0DC546508BBE07A1957B8085E05B9964B46E5ED73E214D0EE6DF9901DC0BFDF1C4BE79B4AD5E1F7290013E7D82360916BE4175A9D20C159785F0C176F228D1B10E235A76A679A07C4A45EAB5CD9F6C0AAB21FA083A7D2005BD1D4CB95F32A8F08E53F98AC96956955715FE639B6252F172F2C84CC28A615397859578B0294EEBCC4C55A083E208E706A3803CC13D4657AC7E482B6500C9CD3E773866014E28B7C74EA0829571DC183BEFD4060FBC01608F3BB2528A5236B3BF7E3CC10FD015645AEFC1E604A403BB7540F2DCAD0DA251697BF063D4502E9D0D9BFBE3EA2C1BEB535561CDFA9441B308A6E3DE88942B69E6AC7A8DCDF9935437CBE53F1145B34808C5B5572B336DB26003C67D62040228D81C8F278E20391A6A3C2B3734A60D5D4AAF038B83355BCF98DDCBB9FA81C56943F061070852B7589A88D600BB13B3CC4BD88BD1913E70F75160A97791170DE5848B1B419D50E7A621390112C673ABF73095E4AAA67DA7730E78006AE913C0A78C40895B8AC7E9BFCCD1322AB5C83CC6982154985DFA8BC71482CBA3AA57A6603C1BB5A559C0B7DC316FCF47C5F44B404AB6E5B8D25DE3994F085F0B777D7A88204680BD77DF5746AE53971BA0FCF5D0F31564E4C00963CE2352F29CC998EC8A2B0C1056B0A9DB8BE094227D540D99E0A0ACBE006EE00189126AA0701AFCC43205BA22A076964E51A3C316FD6FCCB428CD505DB46D8A272CE8BAF96750B5EC53544287A8B82A29D60686AA8480DBE4E826AD7B562E3428EACE68F81A60BEA403A5D99F74B282E95C81D8F71C7B6544E9D668A8C37401CD2F4D5129D19B3D54B9D1072B6C682D20EDD40098D898C857462575662DA380DB12876AF3094A1E20A0963B2A11309D906E55E62C141DC4E03B3D815E7DDD4419C70CF6F816DF7399E416CA3CBAEAF1025E05B87DF734452A9CEEABA7B8215005644C677A8EC0E89517762FC428816D1DB363C53CB12A4C151E0470F88080BC9712AB38D4458B3D4685A005A2F35D5CC039052CDE0D26C22D8A83614578336FCCC0256E7295664355E625CB2C039331EACAB829970175B89A078CC315C14039E62F43DDC6782AA8084EEACF3C40093A93AFE20E9542B56B1158C32A877C4A2145D4E20127102CBF2C013410B3655A0E094FD9B018A90BE787A8B8A1429780E92033D4A732F998001EA5EE6BE71292E8C2711E663848179A5DAD5544C444C51A2363A0BE6634A6CC6F81CB0302B46F4E6981178DB1AA05B416B4598B546C5D35A9848AA56D55C24735CF0B5B668961A6CBCB1C7A977CD705C03D078985CC19F1EE0D1F4E66162DD5A8C89CC9743BFC4056B096CF0D14067CC091A8961982BB5DD7920C42B72D12D700A7E0817005F1216F05E7C45E88BC1732467CC5E04FB8C57A962821911BA040B70E1CCD30C02B06BFB58A603DA072CA394B6EB6364458B6F3C244CAF5862DF2DEE037FED0FDF61B9929AA042906B45D304913512FAB8B417135AE1D3C434652AD3A071733DF88CDD2F2EE22342FE628B2193D2AE88A81B6D1D4C815B6CC3A4BE616C2BC7365DE5C1B75373E21800471AE8DC5DA9EC680079565E087D3A856E6A22E701967F30C03279CE2659C1AB404661D81DB2E30BB7EE5505040204E5DAD90E0148701168B28CCF92172C17E48C21A8AD6BD4BE162AEC76462DCD5BF8943D4D599719818B64374E0BB719BD12F6F0D390A678AA2BDC6B65A896866F8BE0F8841C465C449CD6C4A991BF98F39D9921CB94177A5DC46D0F10AC9DF7858295B867655E2D132531F00806E9AB386AA7843E7467ED8877B5C438E1F899BAD16E1B39AB7E6266309A8AF51DE30803311529AB8032A08F48031FFF00AAA5A363862003B963B5F626DD99811A9682391B4D828379992EDF825130B82B54C59D414BE5B3631453C138AD0A2BA53A2E1F74A079B61FA8DB04673884A97434C2B1556D8BE3D3694896449DA34557EE3CC1960D031B671797C544DB7DB9F999A56E221AE19C5C455ADC81855BBA15862051296AF88019CC140B9B8034B2D0D0945F9DEA0870BC2CE0EA76FCE21B9398C75C2518301E058A6ADFA842056C2B55DC67788B36C5D9A1C3848F7856078E22727F3143776FE6A631BA0BC7A65D1C48E47AA8C8B474CF6F32C036B2C46536D5B4C21D69CA08D3CE399771885508DAB5C5B8F12913B007770332724D7D3296C16A8D571001852E120AADE2502B3444D1116F574F9B2508370BE89BB027E218191CA4B9AD4C9AF21A8134687350B16CCBDD448382CBC11699B283C1C4C221C23F9C0C4D435D3D7F69423145367CCB368AD6EE47ABDC1C0E31FC12C997690C8022DAA6EE662FB040B763DC55291A3CF98D98DB8CC68D94D4C424AD31207A63C18E88D665E61814EABE6766E5AAEE97C82552ED391DCA646E3F933A886E226A03752E9F7CEF7E25E773D446A93F9457502F1E58998D61F799659E069C4532CF25AFCCB8280016AD18898469A75F504154836C01F04D6CF2CCA0B1A6B88E808E4E5D5732C56B3C7A1DC406F5AF1056F319EF10EABB9C002C132803D6263E3EE0DF6DC028A1072DE4F9C5403C827510EE261B817FBFDAE227705ABB8165C0DFC909820BE23F249FCCF5517CCBD0E8DF44A48276972F83732FDC0B2E50F9595E489799EA8EAA52CC1E22A4B41FF1A8B9980AE37071F12B3C42164B07FCE22753C945917669545DDAE2A020C98ADF738F1072BD54A4360F17301CB3D12D0D9A9F10FA05F6DCDCB61BF9895A716B96BE6DFA9DFB9CCB012C55C159E842833E736EBDFE87988A544D6B9DC0C14BB74EC0F4FEE1B2604B38732DE7B95558C4C2575513182A2D4988BDF643C4DCCF1D9F12A1601C0E7DAE625F7EE1DFACBB0B8FC5C6915790E4FEA6BBF107664944AB1FBA2CAFF047E64BFA97A965AB3E21A254CE4B24292F571EEB1F72869C9759E3E271E65700BC5CA39E08D7AEFCB17E55C17A3820A6629CDF88659312EC1D20BC8153071EE5EDB9918EAF4C1EF5317DC66696A4E9886F7B3CE8FBA8800D7433CA4C07EE56AB9CC1178114566ABF4440BC08830AEA55798338837C54A0E57504E9B60F63F47F3146AAA729DB34997BEF7D1080F485F83D1FB9545B03234D7FC7C7C47276724A398F84B212EF637925841C7AE4B43F9980CC42B6CC317B495C3F88AE285CC025F830673F07F72C55C427D831BDD64F9981F04A10A2B99552D25ED89D873261E2FC2CE2294D0EBE5DB1B7025E580A354EDDBEDDC4A622D2ED8280D7305EB44A045777712C530EE2534F93B980A945328CD6AB81CAF092D66A25736E1FC90EA3088A9DC1174B0FDB12CD1877D8FAFD416A2D99C33EE3FDCA2E7031DF8B9947B945DA20A16881701F6FE983B99C873BA7FA88E96339F7DB28AAF4414013CDCAE62BFF000872F32AC225D5A10272CC2B306B27F50CE22C9E1D7DEA22F17DBA8791A7F64117D3B20E02F40AB72AFE23A0719BFA855F9403BED31115D400034B6D7529F0216B1A1E805F71D892676C1C4CC38B64835A9736AF12BB9960D44CC4AC7D4FFFD9)
INSERT [dbo].[TB_MAE_ArchivoBinario] ([ARCH_Codigo], [ARCH_Binario]) VALUES (1049, 0xFFD8FFE000104A46494600010200000100010000FFED008450686F746F73686F7020332E30003842494D04040000000000671C0228006246424D443031303030616139303330303030663330363030303065663063303030303465306530303030366130663030303066613136303030306335316630303030373432303030303064313231303030303131323330303030366333313030303000FFE2021C4943435F50524F46494C450001010000020C6C636D73021000006D6E74725247422058595A2007DC00010019000300290039616373704150504C0000000000000000000000000000000000000000000000000000F6D6000100000000D32D6C636D7300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000A64657363000000FC0000005E637072740000015C0000000B777470740000016800000014626B70740000017C000000147258595A00000190000000146758595A000001A4000000146258595A000001B80000001472545243000001CC0000004067545243000001CC0000004062545243000001CC0000004064657363000000000000000363320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000074657874000000004642000058595A20000000000000F6D6000100000000D32D58595A20000000000000031600000333000002A458595A200000000000006FA2000038F50000039058595A2000000000000062990000B785000018DA58595A2000000000000024A000000F840000B6CF63757276000000000000001A000000CB01C903630592086B0BF6103F15511B3421F1299032183B92460551775DED6B707A0589B19A7CAC69BF7DD3C3E930FFFFFFDB00430006040506050406060506070706080A100A0A09090A140E0F0C1017141818171416161A1D251F1A1B231C1616202C20232627292A29191F2D302D283025282928FFDB0043010707070A080A130A0A13281A161A2828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828FFC200110800C800C803002200011101021101FFC4001C0000020203010100000000000000000000040503060002070108FFC400190100030101010000000000000000000000010203040005FFC400190100030101010000000000000000000000010203040005FFDA000C03000001110211000001E893ED2B0D76F713B33DF3BB33D8FBB7C55A7171914BC3332BDDD61CA6E87AE6157D992EB64670076662F66AB95B17468277047BD7316EDB65AB0ADC5C726B172B9AF842AD602468F9C9B5524429DA53D43A33457E8E23E54BE39158D79B2E57C6C0654E756B40A943E3772A972F2D19ABD51D46652BD22F053F750EAD5C54A6657A2ABD8338F53900B4B3526D20A903A131BE7E727DDD8BA5366BAED27A34F74195AA86A335687CB344C39FB2220D133A3B5D713B99C32EB26D4D3994F4272D862E807561371ADB5F41685EDA57AD15C8084FD430265892F73A4F70997A83274209C56247E08715B523C57BDD6EB724E8179ABA4D108A3C2D0F58A62C8692005AE8C5048ECB63B5D71ED32D7F7B410DCA6B1D160125EA64402D75E7DD1952F0CEBC9C1E771296B2BAD9D74B58DB4A41648EB5CB6C0A83AA80E60F2DA9DD779CB226770DBE916C782A6AB6EDAB4606635EB0202A252BA68EB3A1AFBFA2506B05D6347E3EC4464B516DEADAD114DA6A56686B91336412D3A9C365038502440300D74F4CDBB52A4E6F7428379B35C03BD524772E7874E7D680553CE454A18080532E35DA35556CC3E902305B3F9DEA350A39E76D17982D163921B2367E6D3CA6B418B5AB5C928B5AF3F8DA77B16B2D891E0F2374B086B5548BA19768F2FA5402A669F2F05B2FD4C1C45079B54D9AEB8F74C2C0AE90621955CD182EF32F7193D3637FE7F6339EA00B6DC5F65AD14F2D2E48A4D385A052EB3306B346D3FA236CD5E742576049A2804736DC558ED3235492355E5152A207547362A6DCF36FF320285F7914355E2E9964A33E68A6867B65B31AEC806BE3CFAE8CFD8B0722469695BA7B560C9606E8E39875EF2A8EAA6ABB6B9A2099ED6C94A740F603B27ADAFB9072D73DF02D1816163EEF2E9179E6DD2929CC7C7C8B465BF3CAEECBA172E3C1A8D052402B0A32C15032727441167BE2F64F16E0B974ACB8EB71E885C74AD43D1E9B48D7F3526D96C1D6387F65E3B739E9F0A451C8BD9DB42E8E4D28AB4496064053B94413461BC90BD7A39A3328E58F7E0F5D247CEDA375562CDAED740B02D9F73328632D10FA6F31B686EB32832E78FF00FFC4002B1000020201040104010402030000000000010203040005111213211014223132062024411523303334FFDA00080100000105020300C1FF0031C595DA451B0FD9B839F76C0FDEECA80DFAE31352AAC51D5C7A4FAAD7898EB25B0EA378E41675090FB9B2322D452432BBACFE93CBBCDA549DB2574DA46D462090DF5932D5C48EF519C3DC6BC9DB97350113F2662F329729B224CD11A9AC2360914AC35E2593DAC78F5176AA84649146AD58F03FE4230DEFC728ED86C4488632B078BC201194BBD7C6093B85981D528C168CEB766E3218F9FB72B2318C64127012F0C2CDBE9B7BDB34522CA9B8CE6BB47F83C6F2462B7531D8E6DBE24630A6D924B22CE4B364724D132B349252D94D894132D95844D3967F727809DE413BAB3F7EC04A9824DF01DD961E704B04A1E50D0C90CE704AF946CF178E6AC087A7B7BAA91E5C7FE2948A698D981646E24C93737AE9B167F95D9BB27DF73BE2B90AAC467939B1C008C57CA760EDCB9E1D9F057AF895AA1CF695F3DAC19EDE1CB3D15E1B7704CB575042ABA802853E71A119EDE639761682931F418233B2438221BF0F2F1FC76F956936CA08D644C3DB8AEF3CB5A1B96DE5EFD50289F506595B50196E39E786582078A0A1C07B14382A4DDDA5DC95EDCEC3AF5C4EDA2DE1B6DCD6AFB66D9B66D8A9857C3A6D9E51F4173DB7D8471456228EBC534896EACF39CF73C4A89E4305658E1581171AA8DE5AFB0B3A7AB98D6A56C4F695DB52BB1CCFAA212BA7A031CED146DD885E5B31A4DE7659061D8E347CB2E46507E9C1187B4432B54E27A39E4D59044C85A192D4B14306A962525A49237B0BDD5ABECD76CCCED5EFED2DB9A47B0838BDBE72A247D71DA5691F808F120E324876CAD373AD02ACA5A7689DE6F731D37B5108BB028AC9D42B14C5941368C31ACEB1EC2D411B45BBD23A7593895AD8C49818E01B58B0A5F12E4F14442B965F1B70694B31E272442C1216345E42623B2A5556E156B191040A33AD8AFF00B405B21E4593A7354AFCEB168F84B73821B9618E9F62C3C69613B623CE5908ED8E1E5763674BBFD30F0E308526AC1B9401A9D8AA1665A21DAB41043A8D9BB074C7ABCFC22BF2348791B166BC6E8F4C46281F7289A7D69859D3EA979F4F0874C410598FEC4BD623740CC539453472DA1F4DF529DCFD6453EF9EF5A20F2F6CAEE1145B46A4AF3624F614D9D4CE34955E48DF99B333C762479229B4694C95386C24A71C8469D0A61017202A0531D972C858EB55408637E4AC7C2B9DE39C4ACC871F88C539764DCD7E03042C3042C712ABB658A589626AB25D293E9B5A412C3A25C6AF22EB20E0D623C6D62A04ADFA6E14CB34AA548CCA38CA79AC2711F8B31DD506C254475EB519D601855E432125E3774105E28ADAA4400D644789FA88949353A76174CEA8DAF57F6962BB6CD2B730DB636DB66A60729D38B6F87E126F81F6C041C719D7921D8690ABDF62BBC73C28042B1B4F24BA571A1D677704182BC8F1D48B8191F735A4F164ED87738701DF3504E75DC67D64A3C0F5E78F38075093DBC90D911BCC1A69E3AE1B2841FC89939C366A06996A2AB44595755FFCEFCFA53E39290E9B0C2B929E18C37571B3483CE1F81DFC6F92CA1447F29757EB49BC06D2E4EC8DDBCD6B8D1B7F95455BD684D66B88F95848C34BF4EDD981BE0BF8611E18725CB836B330F031C670231D6439ED09CEB11E6A31B13F43497DA494F05405977C72AD909F4B171C9189F74D1648842A31A24DB0FD6A800988CFEF6CDBD08CB4DC11E77983FDD491629030758BB6B3FBF9766592768FF2B930862DBC8C1F7FA7E2867AD7AAB5542C7D753FFBB1C6CD8FE091E97E6E6F1FDBFDC7F7A64BE41F5FC735125CE9AB4FA710F8FD3F2149A74EFA073B07A5EF33649E4038DF8F31934DF190EEE0EC33FB8C98E5AF22CABC73EB1CF8B9F9A1DA3C4FBD05FF0091553847ABC1D36A29091049CC4FE6523C9F4338C6FCAC1D97F67D987C6472360F3E96A3F322ED89846D9A1BED34B37F1B598BB29D11CF2B4BD7349E59FD2CE13931C95B91E078FA8C09C717C6236D8BE5A6A6C89723D8FF006403151711D9A28B369B5BFD95AA49C26B6385A3927D48FE4F81364E428822E6E13E0E3CFA2FDC679E6DC42E518BB6C5A74921D5A3E519191FE1F4741BDD110E087FFFC40026110002020104010402030000000000000000010211031012213141041320223251143061FFDA0008010211013F01F853FE978D1B3F46C6C8C12D1C6C71AF8289B68DA2CD19704248948522CB3B24AB44CDE2AF2549F487860FC90C2A3CD9463C3FB16347B6992C7B49F67624705DF65592C4E2ED9E9E31DE98F1A7909A6991CB247BE92E50F27B9C4515CDB2525E3451897B07922CDC99978FB23164DEAC961533F8F44E2E7C213960E4595C970461BB86C504F945966F443932BF0608ED45F045D97F6E8CEBDD9558BD3447876BFAB324E5D31C2D1B1954293177662768BA1CBFC32E550E8DAE426E1E496E9764A3F5B317744DA45EBE9E75C3D324F6F4376F931454A0999F0CDBB8A2117B6C9C6D1126F9F8AC924A86F4F4D3B8ED2E4BC106CF533AE11132E8D57C1E98E5B6562E55AD332E45C1952EF492BE3E1DE88C731489C53E74928D5B1AAEC7F90F4643F11EBBBEB6628D418BB210534D31413ECFFFC400221100020202030101010003000000000000000102111012032131415120132271FFDA0008010111013F0172FEF566A5612FA336B2C745E2CB2CBC32DE1F1489C6442348A2B1E1166C86D7CC3D9F8782E76BE13E794BAAC397E16CB13B2386B1B578CD8DEE3489D97484C74CD050A28F32BBC551C7DF4C9AD58A46C2742698949F828B7E9FF0F32CE38BF4E476C58F841EAACFF3323CDDF63945BB81C8F0F6F845763FC26A988428D9690D262D50A54CE4F049E174239E3F71056784E54C8CBF46E989F631663E0C7C717D9AD63957766BF84D1C4BE8CE335588E5E24AD1E0D907D6175D9176B11CBCCA0CD48BC223C9A742161927DFF0FD1BFF006C374733A91FFFC4003A1000010303010505070303030500000000010002110312213110224151610413203271233342628191A11452728292D124C1E1304043A2B1FFDA0008010000063F02FF00B0C27B3BA7068C5D2A3C38217F16FF00D097900755E6FC2F791EA14B1C1C3A6D22EBA3F685EC7B33DCB77B386FAAF2D18EA567B3078F91F2A0D2ACDF562A2D1A3899DBDD5D6802E79FF6556448D5A792AAFBEEB8FD907343C83D1539A6F17F4C0544DE6DD0AAD692E6BB2831B9CC6CEEA8B6FA8AEED0FBCF52886886225B0E1C7A26B986D7041B5C47CC1482239A7385373A78DABDDB9DEAE5B946883F309466CF40C8081EE29CF4DD45BFEA0C9E15251BDB500F45BB5694700E042FFC67F8BD18A7AEBC57B1ACDA6388B5365E278F540DCFCF0684C731EEB9BC1ABDA3711A929F64877205070DD2DCCB977752A49E9AA869CA7BBCE11919FF00E222EC2B81C9D9BDBCCE5C907D332D3B0C381FAEC875A7F9354D414FF28C5BFDCB8FDC2F2FFEAB1FEE831959C3A4A6DC43ADC841F73AD279A9119D095ED9F22DC378290BBC765FC11329A10CC09DECAE815A46163076045AD31C427002AC0E2E458F90428B88FAAC547FF723FA8AD5033F92ADDF7687C4EE8E415302B1B89CAA9680EFE434548D26777791BD3A842A0A6E91806E4E6BDD1988D57BBA39D72511DD30B9BA426F7835123FC229C751A0DA7C4005C17B4877A859A14CFF004AC51A7F65EE69FD97B9A7FDABDCD3FED45EFA74E3F8A6D4AACDC10A43444E8B768EF73401A87784A86EF7CCBC9F74F7B9CD9FDBCBC3958F042759C0A76BF54EA94D81E630D09AC1D948CE4CE8BDDD19E59C26C0A57718085D5DADFE8515FB4B9CCFA42A7429DE08EAA2E7421E69E3BCB2594444646F1F409B41D7341E6745677D4235CB933B87DF9CDAA1C21614B969E3AA077991AB151BCBA70DB8F145E1AF0D1C2221566CC34F94CA22B551869383AA754654AED73B36205D4E9446AED4A6B1E1863A2DD6301F445D740513AF25D9EE758E1ADA7CCD50D6821C3CDAA21AD0DE33AEA853A1E563A0FAA6BE2238F341CE637542DC4F03C106E1DE8328B77C00A46F0E9B4420E3C7089797DCF30D8D3EA9C2AD3639A0E00C95DED1698F34109C5C5C554A8C6BBBCB25BBBA10136A3C3BF512258ED0857431AD06309ED8181A808F7871BA7F28E2BDB7479D0D5C46F798A6BC557073718C61369D63BD8129D469D4C68083C106189D641956906414026808D264FCCE434B78CAD74FA26BEAB29B80E2705791CCC5DEF3E146DB60686755ED59A641050A34E9D10D67C513775565600B9FA400807039D6E2BD996FF535777530EFC147BC3F4B6548A92D89CA21D763F685EC45D3A5C50CD011C216F54A40740AC779CF2429EB8F8823C1DAA6D3752A6E6B065C19923D531EDC8230764C4A74916CCECB79A7DB4C7760420CF8919DE71C7A260B77BE184E754A4F05DAC9CA8EEAE5CE3495BF59ADFA2349DBB8D4E2556347B4891E6691954EBDCE2D7F988461C75E280A556B4C7EE2BDF54FA1851DE3CD4B7F72166E809EED0C4050255AEB8B5BAAA6C07D9BC191C27C1A2BEA0F663F2AA3583CC9EDC6A85CE21BC5402E73283665DA4AA8F61B9FC9A54403D4A697113F6085E5AE9EAA0C4957075B59BA5C9CDA8408C54675E611796543F16F1809BDE06B072A324957F65F764C4BB242A99BC5BC908467572F21253E9D1F3407D59E184CEEE496CEF6DC2C2DF007A2F3C8E4AE449E09D7873FB43DD38E4B148280196A0CFD3FB3F88B464A6FE92AB83BE64DA35CBA0FC4382143B412437CAEE3E88D6A648CDCECA60638923CC0FAAFDDC9343A8881F329A6D13D654DDF64486EF6929840DC6AACC69E85DC4AC6D36E5776E658FE454C2971858560FAA0042C8581B379A43B9A02A37BCA7F94D71777CE6820CEB1FF000AAB1E77C33EE9F027A2F77F95BD4DDF44492EF48535EB39E790C2DCA52E3CCA8188FA2A91C7C3BCA1AFFCA92653FBA6DC434B9132A413080A8C3EB4CC7E34501F527AB1603DDF8507B303FD49C2A7672C3CDA539F4FB596D2D1D2CD15B75D70BAEE05A83C705C144FE54177E760BBCB0BA70D8796DC6DC98F55DC8A8036AB083F327B08CB4C1403F215ACC0D7E88D948B2AF02F3377F850710B76615E340AB3A22CD2E5A9733812164610B5676754798CA8D9E9E18E29829B83AEA61C4C7E136A53F66F6990065BFF0009F51FEF09CC282E8FA26B5A2EA60C9747109C38F04FEE99D6DE217B6B8FCAD514A8D36B678E89A29DBBE736A6DC707409A42181B43FEE88E688E5B2174F04AA2C7367D8B4C8D54B4C846ED65404D6FC2DD16F30CF442AD3696E20A9A9A2F67A1449D1A10E00056F2F01078EC7F2953B7756214BDFF650177C4CF03D142737EA89D5078060F10B28408C2B7EDB2BB445A71B5C0EBC1023EEB22676C8F884ECCECEBB492830E9B2E74F485D0A9A671CB821ECD9329A5C600E5B24EA7013E33036BFBC6E5A5348B4B34F4F07A6CF55840A91B2D1A053B3546913A69B34DA2576AFD5D47B2A5BB96ED2DE1529AB09DE2D91E0A9EBB3D36C2206A8F8016EA148D797804AAB0069B58D2D91969FAA60766DD0A91E57E54F2D8FF5D91B21A11F103B3CC7683CD151C365404E6CB9BEA328966A60844F166539A54271EBB606BB31AECBA31E0010EABFC6C011B86DEA984E8A8124F97508B1C6E8DC2534A7F5CED81B600DE2B29CDD0784420D1A9D7631BD53AC734FA2EF5A239EC3CB60A55FDD9C877252DD1F95FFC400281001000202020201040203010100000000010011213141516171811091A1C1B1D120E1F030F1FFDA0008010000013F21FA6895FF00AA430B62790948CF99462DAEFF00C46521F0C5ACF3FDDFA01FE4A4AB951D736B388A564BAC84F7E117F5433B282CBF99F78260386F87F2C4C95774D7E202108652831636AD288C2E231F1F5111F131C457E81F01D41C934FC3896010ACE5257B6763CB2FF3444BA2E32ED0682A53DCC7B5F5F4E821F0304F327180F8886783196680292E1D26F8EA216BD712C2CF32CE0C66425B00BF11AB3EC716CE38C409B9800C3DEF28DAD5D78130C062D9BDE4760546697D042EC9BA4CA186AB9296C0853D759C788AB3629EA65056C6FE65255D821C3539D98F2D54254B40A9652978B946AB394FD7714D70F0E2E1F406D8DC26F4CE23452BED3A98028F44BB0A9BB7DD0E8EA24F21156C1710772ED8EEEB8C9129129AC0952CBF867F30B35F75398BE47E980B63D0262005ABFBCDBA19037065BEB647DC6EC8C351F11E3E36B2F16371BC6E6F04D077E65BC170B62E1FC43049507022DAFED85A0BC2A26A8F20E996B375081C1B8AEF72CBA6E75402541A364254A190F1483D0F4A0E13308E22A2EFC063983CF41F67DA6300336963C4E698187EEC6C91A8018DD5E0035F6CB46DEAA23038352952A76D16B59E7CA73614D1732ED3F8398EE42AC1839DC1398DAAC2FE6036DE22D99AC544F8021400D1DDF3306AF55B22DBF8A43709EBE8E83FD69FFCDC04C0D58DCB80381E30DD4629BBF0A8B14B634A5956A51506431D01CC2A0D179C4994DF5473D1BFA1A99353403117F29801881FB6223C12FE046F532F21798FFB51F39E2F0C1E31321C2DA5EAE3A1DA25A75AA56DD9A799472435569B83D8D2D010D28A35B1E3535E1CE14BFB61BFA4B85AE20F923D865508080DB94AACA45EE4B6E03FA98C7529D1B30C2B397997A05BE201AF3297882F9FA55D1BE674310F4828AC4C2C516175EE5E2AC83FF6E6DE640E0BBC5CAF57AD0CBE603476B334980585B409E262EF472057E25475F997DC6EF74B2682365EB13064F2784A41BE1B53DE7BBFE6563E0A8B51DBD40D3B38B2E54CE7312143498836378B4B1B58529D4611C7B45E267A2E5FC2A94CD4AB4B940515DDFEE6E570E621953632814B526229B6EA85E653EE08BB0C8495DC6A656A87F503910E07EE220C1205D8EE67A89A2CF15F12F259B46E2BD20102AEF2B9CA020BE51ED3BB55F6EE06235037F18F240D6914E1F98D43C7D4F7FCC5E275086BC9175D35710E9F44CE7A9478CC5B54FCEC270AF765251A0E21AC24BBBEE9326A895E076D5B2BD34D941E220EABA81802EB0723A4CFAAB7F3BE63D095952FF508B5F80BFBCACA7DE83950B8A59F685085B80EBD4AFC8CD9FDC04A168C1570342AC8AE6FD462B49CD03034B48BBF2C63DCD59A3173790304752D15FCFDEE78CE43492E834BF6FD4C90158E127C9E9886886CF88823058D90E9C13E0653970D08B77128BB7A989572A93291506055526172B61AA81A25D7F7972A854D93C4D9E0696765FEB10B638D8F1AE3702B52B4DAE00834D012E942F6C5B2B6376ACEE6C7051FEA6766D956AFFD46AC131B85DB8B8AABA8CA718990FF00BD9A841B39E5400B3116FD76EA388CEF5404515823C36A66881C9AEF2623EAC6305BEE04DE1C56CB5118A5A20E46E95480C7825CBECFB626CD871CFDCEA0E1568F035C41509FC0B9C13CB003CB2657AE08AD5DCBE069DCA0E2556AE48652EB04AB68780AC3ED124648B49F4543A1F2637445564955333CB11A7A69B4BB5459534A42E0DD035F0794AD8E796588D73555301AD404F24306C6853712F158CAA8EEE69708792C203353C363F1996DC54425459AAFA16ABE6021E6B2A8FEE3B416BCD57E6241A2E794CEC697E5ED8DD9B958225A44B9B7CC43F940F210AECAA015F33AA044C3F3060A870CD45E5326F6B399AE0E047CFD20DDB3401EAE58E35AA54495AACC08A11202AED7CE1283E845787EE1C6ADD9805D7D62CE28F6B84DF5CA503A19AC51CD73B5E663B08D050886D332648967DE5E5363053B9823E65CB07A446C23F2DCBF1A60E0398AE596547177919F3C097DD704901C85FE1A8E5B1E43FB4F004DF1FB4469FB5F8975A7054DFC732B4650832B4910653D20029DC6AE5C747A42DA6BE8757CBF29BBDB2218660A5CB24309F1211F94B757306ED85485B16A880443679D7FCC50C383CCA18B152051ACB3D7699F0D2828EBCA5A829F43C502CB4CE60C5561739657582DD463A862015F72365F66EA2E42F72F899C686C96B22B062AFE25C53D23B3E861C4C0CE662C55A251EF9B357BA4BC107323EB70886D28E437BB10CA70699D04E69A5FB7130856D97278EA72B393F63C4D3CA1A83CDC099037435D7895748D9A9C83DF0CA1C27057FA81E127880D7AB2C8E151F9A55994EB8731C96FBC3FF0C40318F3370CC4F8D96150596F417336C0694A896165DB2CB75DCDD3BE932A9E0456B9DECB3662F54C00F9839A94DBA6BC4CF80B0131B7B59E2663DC499150F4214C30130536C02ACD7D176B2698E669F898923CDC19F6622207DC0C8287F03E23855649E4E2304A0CE23521D9925EF27ED2D454021CF99CBF70CE0ADBB0D46D448625B8655EA690F30847BCDFD3756E711814B0E1F702A1E971769A1C7737AC7C4C196E0F0A3F32918C6EB998B3A945F120411B08F95B76CC144B0B5CD94AD1A879704429502E9DEC36479F10D4128201EC13701956DCFF00826F0F19C973D0468FCA1ADE67398625177A89ECAF2C3974995A0157496DC367F407B1098C98E5F0221CB73A9FF9A8799A9384793AB3106AC9FD84B0D257B86284DFD54840441EC99AE8CC0DCCF10D94B0F998536CB86708AF56887D3CBA43A471CEE5D15E954ACA4777895659A9E5DCCFAB7F84FC92A5292744BA3AC7F7CC0AA03CB2CCBE7CCF831DDD0A8E16F72A641CB34B7999CBA5FA3F430DC6A35A0D4347B98AEE20EE23530253014699BAF6EE5FEE6161AB7BE9FB963C889F0B728307F07995397A964B574C748194C34972FAC4D2DF29991C405BD51EAEA1B07944FA6E6FE6888197025B6A4EF227C498472CCC05352CF151C4804D1CCB5EC91FB46AED5FC929BBFEC13DC34CA19A54F99BC170C2C2F2CA6580DEBB8BAC49F15BDE49927A25515886E2A2F51A8D9E3A215B8FE0419A620FAC9F503D51C5AF2417A9AAF69567E6014460C34D97631E1842B72FD3B9FFDA000C0300000111021100001089C501E7DF7AF31EF22446F32F41550D8B82D473D8027F130C27429AF998C1C4F430114DD6692AD8700ED8B90353210B2CD3BB1FE39203C775B3D269880C3E78C4769687AAEF64007AFF00B36F63719A9641D580F20459C7C4DD4AB94A357EF3F245B8C61BE6526432421BED9B91FBB0316BF27DD89971F636443AECE903F0E7FFC4001F11010101010003010100030000000000000100112110314151617181A1FFDA0008010211013F10CB3C65FCBCEC3E739BE3E0B29B0F43C0647D333F1BB00C0CE5EE7FBBA480BBC9179242F90BEC00C6DD9042199037D408FF00C6DEFF0008E732FF008BE90FE5AD81369CE493D4DDDC7ACE7A19126DA3E405C411A1305F7F9680C897D4C7BC2FB3C8D8A1DB36D84B969E323DE24DF6476043B21AB00EC04718F931BB6C95AB6A87AE4BA8F636817FAE92F03F6EB1CB9E6585D61020F05C87266C338956ED8381089C04235D976EDFD9D818961E3B3F423D596BE30CD2EBC7DA2601CF63BBF61F0515DEEDCBD966931878925AAB448C67B4FB750C390CD993F43BF9F65C5F56F75F137C7B238EDD42D3ACA2F2D9D749263AB574C91090ECC14D9593DAF83E5611391B1B1265AB6EDD9FC7F2463FE9272496C992C84E0DAC4220DE4809F721590E06F5BE78038FD81B1EEDCE90B63DE442862F0004ECFFC4001D110101010101000301010000000000000001001121311041516120FFDA0008010111013F10DA5DF9C7E017CF8B44BDC7E1519AF08FB2E78DF84FE2DFC8E23072DDED906191A5961D09DDF7E011962CB5F16A6A487A4C7745BFD61905B7C3B25AE889E010CDE4FDA55824E046EC83996A7F21416BAB1D46E4B0F21884187C0D7D32751F5DB75DEDAEF65EF247A2CFE4353431CCDB38DF9074DC52F1D2191013F528BACE3D2747B09DBF18E9910C4B33575075BBFB1E11086D22087F2E9C112449698B70845CF67EDF2F049EA43C2E416B0CCF5B24AD969B2BCCFB2AEF961C12291EE42C088D13D33FC168872738B1E2EFDD89807B0085345E242E31F8592E5ECB93F8142D1630785C92E96D62106F7CBF17933F86675263F96CB14934FE99FB37497B78939898E98C4E26324BC9D192F1BFFFC4002810010100020202020201050101010000000111002131415161718191A1B110C1D1E1F020F130FFDA0008010000013F10A4A64BAC8E1193FF0007FF0086A853B618285AED09503D1E705B0182AAFCBFF9D708B017047395EBB91FA1C9993338CA7F4BFD3958148600B129575E71B19B45CF8D67B7F031FD5BADB2F473E1CEB1747FAAFF0001FDF2EBCB0E987778A00FB4EF0C215DEDDC1471E082D04585432C879C7A28DF5BFEB5A3DA1B5FC9B5F58BC54063787C5E67CE687E056C89BFDE12F44B983EBB75BCD5569742EBD9BC9E10A81D6D26DE3F196301A5E8A8FAD6B00A368EED06790F73FA3C43BC76EEBDBDBE3023212C25C80F1F8CA440CB0E3EBAE4838C58A2BBF093BFDE6B51BCA5762C9EA62AB8D6DF70E4FDE40A89343D3DE2E7BA6EBE17BD7C6203539BFF005664643E93F23CE413D407BE0EBCF3FACB838E6A85E78C984B0228E8302BA7F5ECE78C2852506F82C97384074A17E98E35B4B602F6D6E4F501A7D76B3F59CFC8D95796FF008CD8B9C02975E5277C60A61C478D7986BADE14AE28B1BD09E1D98716AA1CEC2849DE0046116C1001DB6BD4C259943071FECC28C5AB83AD9D9715C78150501CA1F1AFCE6C764234E40E8C10CB851AA3624DB8A51898A07CF87D6222F01433487C05B7341D7D606BEAAFD3E1F590E7F3193242E25C952A8D638D20F7A2B1EBCFBC02FF00435BF590942B1EE7D266D2871233165F988B80377D86A3F0E02F56A55F101C6275FB4B225D4C33223CD2E3A7FF0032E72831DFE1DFB7132CC9940E177A2437779DB89ED4B431D8597B4F4F0614361C33BB3F8FC62D595AD46B93FB6337601038335E6658A05A94DFA1FF00B8C4366F16E7CE50CF5A30040ECD9D4F18AA9528ECB80E6E023AA791F79A1DEE1A70AA292F12E3CAC29DD2DDF5800A5F607F0E6F2B44FF00672C4EB8153A9BB9B24E476DA0CEC7345A624CEE212525D0DC62648E2694800239DD7EF2A18ED5079BCABF1857A6387DF8DB85870BA3C281D7385538EC14F99C5CB6B0BE477A41FB32611EF8769C88984028A4AF0A7D65BE8FCC72FB39B8E4BF8C5034C27FBC8C5DFD9EB2D8DADB73855D8F78C054AF171072925E7CE6855E4C55CE8F539CA185B7525FF38924D0435F1BB825173B0BF8C24701A3FAC03B3E439C07FCFEB00680FF00CF59A237C015C1C622A0DE529C1D75F58B3080B2C4744E31356C0143BF2E796E01405E74EC377BD640318466A6CD5CB6ACB443E57439ABF03723011F7A719A55CE17048157120ABBD6140032AF1EB0BC08E5DD72701B36C5E4FEE64F51C63E8F53D98E050CFF008BFA31DB9585009F0890DF921804217B458D6477ECD65376314EAF1DF380D1A660445A046DD6F386BE83B49BE26216ECDA1DBBE8C286B003C0039C58E66F07534793967C60E0D36C15FC6124EFCB8F6493581A298A42B0DC7CB0DF38CF8EB5016FC3378B50BDDBE5D4BB584C41EF428CFDD30747E84C84EF52E5C659A1E0C87ED4CF9EC59D27B0CA43C5B5E3274F824C1178BBE3032D727C397529C53B2AD71C4FBC068CEF6816F5E53B8ECC04A36A0548E5DA5F18D17C515ECD19DDE73968E0A051AB3E8315A95D8E4061595EC2EF0069A82C524350F9C04A709252B4FCE2E7274A4C7B954160C2582694479B814E0BC20508E0BBEA2F18A4CAB4A709BE1AF8C468506C6868B2EB46B2D1F2F3C52790E3E6E6C651DA6F8F465F51F833A4FCDC780BCC832F91CBBCE41C562BD293EA620A5E03F7438FDE37591B4A1EC23ECC86A5502E78EE439D1C60A6B13E0B819A44351AFE4E228AA818A041B6758083A84048BB38394C2081A4074CDA1AD64D975ED874C9B25BE0C919C43DBA90486D1F30C030915E59DE18FBCAD31F32A81BE74E2F38856804764931E6880E8C87AEBC758893666C1E0860F3832451E8953C88339C6C11B98BCDE05BB70596B704112C023AE9E3CE1808808DF2445DE30846D88D97E2B8038899623903E47F8C362F4E367A1EAF8321183A6D53E38C066522349E260E6444E477BD3AA8E31202A8664F77A0F9C336603CF02A9D4EB212589CF4A8D13FC61076C2D011285E1AF8E329BD44E0F2869C9B5B8833CC207AD5583260D2D1E11872172445E943F0FEF0609085BB8D0B9C62F9556984DEC0EF4E03FAC01157FE4CA79E11000ADF3883AA0FAD5F69DE386A2ADFB89CFDE6D5D293A5D1CBD6569D32286BE38C55A436CAE62F86180339BD736C50DB1399BC0FEFF6884BEFD64679662553F01E3E5D380142154A497871DB03E03FC669F30024ADCF731F4256821A43B37728ACB0FC01EB4E05B85A363FCD98F345DB95E476E1854130DCE9E05F006412DD727B5FED8DA03421FC53FC65B6A810FDAB7818821A85EE68FBFDE47E44D463E40BBE43C38A17C6EA81D4F95F7BC1FD608920EB8C5BCE889ABB97F583F51104D68D0F8CB208435C0794D35C169D022DF27878C087016096DDB5F6F783294DA017E300CE2AF280DF55521EB011B4700F27626B48722C1CDB16402F8C0BD6B264AED3346601A9E0F879C88158B01FE8C109013BDF63CEF0AE9011176279CD0C1C00E003941BEBDB950C428AB45F10F580BEE9D4F0F4FCF3837010E4705FF78CEB20207C4EF00A8A30DFDE0D3472C16C6CD8711D9E72FE36BA070A7068BC2FCE445D989391DFAEF76E0AD93597F0477CDAE7A216D21B3407A97782880C34084DEF5B9E30248B07FB0F7840DAB0146FBDE758222D7C7BC54050C62558C2693E69B894D18D10001559E2BFAD6706BEF25B77950E581E7C63DC7624EFDE2C15A2C2FA737C0909C99212169E4C40410ABE303844100EA7AFACE77530370C3365E64E725B4F519D71AEFE71EFF2C67498BF00995747B4BFCE2AFBBCFB0047ABC71891BC1AAA0FC67D0C4BD8CE1AA0D23BA5B8390FC84FD405C21C68721C903F271D696137F46F164A223EB84517A5C9501E344CD2B91849797E32109E62C6AAEF99380E31AB9016395EF37B62ECCD8030CDB4CBBC1FBC68A7503A0B4D0FCEF2A08DC289E44C1049C0B57E301168014F78E24D062E8F18425FAD815C24562510D67243BF581BB534B6706DB90687DE2562C3EC777A4EB2D91468FBD2D4B7EF01348F0843E41AF664F14758126CF3E1C02C0D6F433A2657A3BC87F8640325A2AF8D6B0874E462F8AD5FD66FCFD11FC69661074899794C58F7C5D5D7F9C315D50C2076703C989A93D370910DADCAE3BC69BCA817800336D668B47BDE38328D00AA9EBD79C538696E6D440D3F19A386ABC1C7BAB43E830BF055757A7A1E7BC95F5E03C2CAE956BDA98288A9195F9019CA17015C042C3C53355910847E3516F84F8C829917B073F34CBD000AD47F3DE32123C3687EBAC7455A4D8FDFF4F0041EB6E5F8D4CD06FA8709EDEF0014F43AC708FE3DFF0079ADB6E32E3D8C52AE34336051E30A023EDC8B7A3485D6DCF28049A107A4144F0F39CCECAD03BC181694E1FED8B49D58A173ECF0076A615617A80DA0D273F5CE2712138BBBBC7BA950DE020B0B629E8EF00E3B10604FC03AF18ED1738EFD2F009727A6475B3A4FF1970FC545A5A37B3357F387F1819CA25C368533C5E3E9C4125659D77FAFE31506F29773140F088BCCC144AEDF0EF08FF4E6B9B8DA344ECC5213ED70EB7102623A890076AAB4247BC9F114467516CE4F1BC3442380BE3DCE3EB21DDA6D067913051B293B0FA5ACF20F5852A971C8768FBC2608200E2B393562652D08391F8FFE8C072341E429557C9819D4D154429DE87782AAB59C23BD75BC24B1762DFF00CEF25F86D3A1EC32AA883C3758E60F90670FD6F9A97E947F383C0917D931B244C7A3328DA389D79C151D943A388BA7CF5CFF00C651088E3B74C629EA076E0E77BCF5E335FE03C2A23A4934FE702A4436CCF2571A5DF37777FDDCFB146021234E1B76FCFCE5F8A709B8BF5F9C2DE3D39AC4CE517E5E72B900D1FB3C62DD92C3386E7B995A882D429B7CB9535341F2FE0CAA1A0B4939EF1DEDC71053BC0F6B3E07340BC6B22C04A6F8DE40AA552423822204E8F182447E47E7D9EB28AC7D7FCD66944F2D21FAC1E07CD4BF0B9A235A9DD7DB87F571E60918498452F8EF595AE081F1A7F9C62D82C3B9856E82437E30E609AE5962F56691E1EF20A9C14BC1D98BCB71C34CB2696C9F3BCE3783533943DE3561F8C20E3DE3C05CA1151EB7C63D686D77F2EBEBFA15EA367D60D634574F0FF1968371B70DB9C6B8BBC424E4D3F1F194889DD609BA8EF4639DC575D64108C81DAD19BED000DC76E7CF1AF8C42A3F6FDDF5300D1A8F2238B16F16A73D7272F18A4CA7496DBA9AE718C3A145DBCBCF786529C2BDE2FF00D1CDAA9CFD60C68885A0957D4C08385CE2920A08DC1568089C01F789F9E58A9D0D634EF10AA17CFF005D902037FCFE378A1528DB937980BBEF34AEABD31432A23F26028E1367F3888B41DB80A02DDB084F43FCE29F9739C79C812DB8B0E05DE2ECFEF921A657FB0C02006F193F598A6405870191C12E628D183561184B81270BCCCA51EA0F8F59A1C461D2BF95D6204509CA544FB27DE5D4218838734CBB71531241B408EF5882BE1B1EB2B0BB53DDE73808AF788D5680DE22474D2FF9C6D5785E8C765B5EFCE1CEAD5714B5DB94068DE72D980AE9F4E0922373B5FF00778A9AAA75301D1F0EF11ABB7584028535D6F2163141577AEB7EF34427F0C7200708F787C2419A26DFC61CB76456974FACD4107C6747E77F79B4034175FBFC604340EAE7732EDF67085C3543CE51B36F9EDC83680DAE0693E90D7F9C489DB6AF78D28D0279C76E69326518E9B8803474E68A29ECD38CFB2B3C026ED6DB8B0D3F3860AF932389488884A7BCD236C3D3DE0071D1470EDAEBB103EC07DE200A4DE853E8D8E51320B2A708FAFE3081C474AFCDC42E81A5F1AC0E10006F6E2A383DBA7343C5AB31A81D224D43C3824047204FBC41C479D38213AE9EF1E102608D2E36BFA13E590C81AEFEF36E02179FF58347B9A9F79A22DC06B1907DE6AA1121C7099B5A17666C4E2E6A1278EC4D39558244E147F7CF238C8B681F664ACE48E220FCC4CD9C4805845CB8D092798B8934BCEDEF20376776E235D9DE181D7B76DDDC5CF9A0B8D8384ED76F589109A886FA3EF0A1521BF0F9C199249AF3DE6EFD608B2F05A12F79422EA397ABE5EFEB0900294A0795FE0F7934513A799E719A905F036FEB026D186B627E314C84291F49D637553CB9C5444321B75FF7E304F10038712CBC88E4F09D97F19CAB00A8C759FFD9)
INSERT [dbo].[TB_MAE_ArchivoBinario] ([ARCH_Codigo], [ARCH_Binario]) VALUES (1050, 0xFFD8FFE000104A46494600010200000100010000FFED009C50686F746F73686F7020332E30003842494D04040000000000801C02670014793876357470304F62412D46352D357254796B531C0228006246424D4430313030306163303033303030306264303630303030313930623030303035313063303030303663306430303030653931313030303063363138303030303736313930303030393131613030303062303162303030303130323730303030FFE2021C4943435F50524F46494C450001010000020C6C636D73021000006D6E74725247422058595A2007DC00010019000300290039616373704150504C0000000000000000000000000000000000000000000000000000F6D6000100000000D32D6C636D7300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000A64657363000000FC0000005E637072740000015C0000000B777470740000016800000014626B70740000017C000000147258595A00000190000000146758595A000001A4000000146258595A000001B80000001472545243000001CC0000004067545243000001CC0000004062545243000001CC0000004064657363000000000000000363320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000074657874000000004642000058595A20000000000000F6D6000100000000D32D58595A20000000000000031600000333000002A458595A200000000000006FA2000038F50000039058595A2000000000000062990000B785000018DA58595A2000000000000024A000000F840000B6CF63757276000000000000001A000000CB01C903630592086B0BF6103F15511B3421F1299032183B92460551775DED6B707A0589B19A7CAC69BF7DD3C3E930FFFFFFDB00430006040506050406060506070706080A100A0A09090A140E0F0C1017141818171416161A1D251F1A1B231C1616202C20232627292A29191F2D302D283025282928FFDB0043010707070A080A130A0A13281A161A2828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828FFC200110800C800C803002200011101021101FFC4001B00000105010100000000000000000000000300010204050607FFC400190100020301000000000000000000000000000102030405FFC400190100020301000000000000000000000000000102030405FFDA000C03000001110211000001C7ECF8CED20F7511F7601A2B8091500D15204E5AC99166053DA5CDCD3E85F234DA222A10D11C04878A9EF2E3029E06851363DC53E10655E8C724E8BDA78AE8D6AF8D5651DAA8E58B670946E48DC1D7842412E8B94A9287A06372719A38DDE128C08C1D4EC62EF2B9F3F555B9E948FE6519CF3C0D16490535B9DDF9777D0B37C53E5E70EC49C55F675B5AB5E71C9ABD129479BD3D088F271BAC69470352CBA7CD6DF3D7E166A4604E8F2F9FE03D43CF316DCF569E8D14D329449AF8FDC42CE4EAF65CE0F394E12A9747CDB4A3ECB77CA3D53664783BD958D3C41A0EECE5EFD0BFCEE8E83C5FA3CB371BD67218F764DCB7530F470C37A1653B3BDCF5F575AAD2AF0B3232ADD6B718D25383FAD7937AB5F9F522386ACB22022061A80F01D58E774AFCC2FD1E61F91EA69E3E972B58F43268088BB1280A86B67921ECE2694640CBD604ABCE6D8A0D43D6782F43D9818707BF3A88E4D33BC87825152E6F576825CED39B56A658F36C2DACA344CACFDAA446A7499B08DBAB1A34E139ECE17481998DB39D3877DA417EA712E021169E0320454E4CC2C8D8C6E576A98E124CBAD5F4651155B73666E36A73AE17E842207980895BEA79DBB5685D0F17E8FB39F6145F5F3D4AA8877C54E03BCAB3B338068F3BABCE69E94ADCB9D140A36F400A961CB1B1F4F392A23BA88D434AB389C0F263EEE24DC7D23239DD1D18FAD83BE8CC12C04996551803098B0759C9935F4E54280DC6C6AD2860E9D6AE5AB10301C6DAA4994A3271BA44986407DAC3DA9D7D48CEB5F31895E048A34A40317631B97DD1C6E503556B205760B0C08D168695AA7652A4C9A49212490DE5071135722C8BBA180FB395647508DD87A301929D80F3FB02CBD5CA85A7CED6A29E74643BAA8B1E32AC6932492409240EF17091C061F58F5AC5FCA76676290D99301AB64EB2CCD0CDAEEB609C14B3EBD9A96D0927941924092409260776413288A1D068E56A5DCE80D93845924FFFC4002B1000020202010400050403010000000000010200030411120510132114223031320620234115243334FFDA0008010000010502DCE8DFF0EFA9AFA7A9AEDA9A9AEE2744FF00876D4D4D77D4D47BAAAE3751C405BAAE2807ACD3A1D5EA95F53C5789752F35DB5352FBAAA059D630D23F5E50D1332DC5C51D572E3756C8E2D957DA59EC595E5DC817AAE5856EAB9645B9F95647B2C6877A3E86E711B108EC1D91A9EB36A01D7D664F5AC9B63B33B0075FD013253FD2AEB6B65D55AA4F380FC8BF6661A6681B453653899E40600C27B01A9B12BB2CE0A087572D194C1C84683D45FC89D15F52AA6CC8C76E997B22F44CA59474CBB1D337E10636465727DC3034C3B7E7AF0FE269C6E9CF8C5B132458D8B61286CC6B2EA59A8F83E117045A474DB50D981B35D4A92EE942C9FE1EF166274ED32CC6D8C6E4F393C7B4A26765BE55BFB109E58196E2CC9EA298E2EFD4176D3F50DD2AFD40A651D42BBE792C9E4B2792C9E4B2796C86CB2792C9E4B6289415F04DFBEB4DFE91FDA0EA51630960624F7DCC0EAB65128B92FAFB19EBBEE620DC58ABB99F48C8C5F0304F1EE1A4F1ECA0B362D0B4D77D0AF2DA4AC235FB3A5E57C3E49107A866BF662CF5370FDB2A8F1BAD6FBE3A1757C582CE9F8C14431D4197A887B8FBE06433E1F904E5B05A187D76C6DC0D081AF606596F283A5B1A398DAE1837704F8A0487065C7E466F67B9983FF8396E10F09D05318F6552D600B0560CF1A83D4D1ABC90DB5731BD9E25DECAFC38EF69D557F1756DCCA41DB5DA8436DC17501685499C744FA81BB55B8A835F22CE532E9F2D254CB76A7ED308A574DA4116E2B815D2C4AD32E402251CC2D092F5F1BF42AB9E67BD02BB24EC6C0F9A7BEC901D462495FC9B3576D628B6D55F13D5F2EBE65254D5606A613A0E79BBE92B40757B73B7A562FC3E2F15E5A10EC4E7A9E459CCF6BDF8382AE8B72BCC8B4F151C436A6313623636CE3AB0B2D6E7283C57C9A8F77295FE47EF9ADC461D26DC93488AAD35A8558CE13DC1E8CCEFBA5CD5A8F52B62D622A9B6DC3985B0D9E4A2D36940F74E466E2FA887DAFDBA82373E9789E145056725338CF0CF1B435986BB034CFF00CA18AA1471AC5F733EC57C07513C86FB8ED48D33E52D71B2ACB2CC7B12FAB7503E448D746B5CC22C33C8F0161DADA7CCBC18363D3C6396F2A1E055163F397212F620DF1EE235A7B098194687E6A460E5D792FE1433C227899672267A067B33500F2176FE436273C6B750A92D92FA769FD575F28E157B6BB897E6DAD8BD14707F91A78AE139DCB090D3976F735A872912BB09318FCA1985B758A630DCB3DC2673D0FDA26B90E916FBE0200AB002D1C5F1957B3BD683CFE40468DC7D2AB3C0658419B96B084FD00674BAF9E5116A9F35BBB1DE79CEBCA75338C45E3591C0ECAC4FC396E6E3B43F444C17E37F9B7374B44A811FC8A7D1ED95EEC004B3DBB8D4AF466CB466E51881F4D0E8AB19CC68CF28604468FA307E3F7B587AB166E187E9ACA86E8EE2341F76D053F2D9FD591FB543C973AF16FA22637FC0EE6FB99FDB19718A76AF1E1FA8B308FF0019D6F7DFFFC40026110002020103030403010000000000000000010211030410122021311422415113323361FFDA0008010211013F01CBFA328A28A28E2CE0CE2CA28E2CFC6C92B47E3FF0E270471456D5B3456F29715C87AB4FE08E6E7E0BD94BDA2CD7E10F27F87AAAF81EAA3F47AA8FD1EA23F47A98FD19FF009BDB4FDE271DB1C7912C75B38A7E4C90E0FA351FCDEDA1F2C514871441C521F825B6A3C17B599A5C60C8439BA316158DDA39097266487D10B251B63834ACD44BBD74648F38F134C92B5F22EE3455BA22DC58F218FB99E6AA872B77B5EE925DF6F25D31C9B2CC6EBBB35937F1E36B459666938C2D0F5529FB51CE2F67DC71DE51E4A98F02841B974678B94290B14B07768827231E2715EE1A486FA332B83E88BA1E54D550D2C53B42C9D86EFA64AD574357B490EBAE4AA4F79F63E36975E5FD9EFF00FFC400251100020201030305010100000000000000000102110310122013213104143241512261FFDA0008010111013F01C5F245965966E37A3A88DE8B2CDE8EA222E99D41CD8B232D9BB4BD1365BD631DEF69ECE5FA4B0F4FC8969B6D8F0EDFB163FF004F6ADFD8BD34BF4F6B2FD3DB4BF4F6B2FD307CD69EA3B4ACBD25D852BD23271F0427B970C1F3D3D5F845D8A43BD16983CF0C4AE43746596F451E08C89509F614ACC0A95F084B6CACCB22792BC119D8C7DCDA48C6AC4A957065B6256550D15A4959E9E2BEF8E356FB8B0A8F936493B371659E4A13A164DD24970C7DA5DC8B8CC9B51279137FC884B8637FD7066F2FA887112AE29D32ECB2F54E85CFEB4B11F7A479C5F62F4FFFC400371000010301060305060602030000000000010002112103101222314151617120233281911330334272A10440526282C14392A2D1E1FFDA0008010000063F0256BF50FCCDAFD43DD67B4637A9447B61E4BC4E3FC54B2CED1CAB66F0BC45BF50596D587CFB336D68D60E6A8F73FE96AC96048E6EB8FB28189FB89D91CDF65008C5B952EB6B4F5599EFFF0064431EFF00F643383FC6AA96BFF143BF753818599EEF32ABADD5457254BA5AE77915DE0169F647B83FEC88B322C5BCB552F25C789EC09A779FD200077A23861C06A4542C905493552AAA868890A5621A0502568A5C239AC66CC869DD4FB331C502DDF65062170279AAA985C144AD60DD166621FF00A67643BCB334F9ACD1C36D655FDA9CF786DA39A32866A9AFB7B3161FB70D7FF4A3EC9B819F755ADE1BFAA8BBBA5208E098FD483E483859B5E37628B18149C2E130ACDBF880E703A60A808B4E679330E1210706069F9B2A2CC32DE2B2D88775DD34FB179E2C1B26B4FE0C97745DD31CCE2D2657C3760EB54E16FF008776076F69FD5C60919FFA5F11DEABE23FD539CFB478035AAC4E26078676EC841B8AAEDC2EF2D5D3C015DD081CCCACEC27A397782D59E72BBAFC44F2985E377AAF1BBD578DCBE2397C477AAF88EF55F15FEABE2BFD5556107E65C96A80AD5D5ED4AC9E26D42976A7B386D66D2CFEE107D93B134DFB5DA5EF54CCB8724F67CFF2F555EC868D4A8D4AE7DA693F0DD478BBC26EAAAAF96E2AAD954A10A3456B9890ED25725554D2EF68ED76EC53B3625CD3E1D6ECA56FE8A55452E742F97D545169239277D973BE543F4D5705454ED5888D1BA29142B8AA985ACADAE6198035548959A17352DAB4D7B185A24A8D5C75BB91BA47619663571850D95F285E255715BAD3EF7530F9ACC4475597C904699868A002A088BB1FF90EFC11333C94B733555B7CEC8E2C48B75E05633A598553E8BC4572E8AAD95058B5B8C93D38AA598038AAA1C9780E0E3C57848053A81D4DD4C00B2555537B103C9154D3408078EF1D9885384FAAD7D551CD557852337454102E6158ACC50F00880809D4D5709E4A0A734D42389D4D97B46EC61666D79270BA026AE6A06AE4C6735324732A8E07915FF48684755ACAF861786E62701F37DAECC744D99E67FA591D1D51FD3BF5460EAA3654EC84D202C6F30F7ECB58E8557113F4AF0C2E6B45E374A907D6E65FB884497022D05381582CDAE1B2860CAB0FE9EDF13C134BF406602168D6D0F3BAB8FC8AC84F9AD4F9153E2E6A1CF5B9E97103C7B2820CAF69698695C28E5FBA0D74612564A5C677ED43697FEC76A15710FBAC0E0E61D792A5A05495216623CC4AF137F8D2ED2549807A9088F5CD28FB4891F7591BAEAB04449A225C61102636526E2B89ED32C361BEE55A3AD1A60B6974D9E8B34C2A92D2AB3E9751C5BD149B407C94EAED82E72B74D31BAD54DF03DC7B175776AAD9BD6B68D593F127A3945AD987F3598399D6E25E093B2CA0053A62BA87CD1C3E6553DE65D6095AFA95E20B3D9B7A85158E6B88BBC94285C509A354368D5974E2A9EEDA5676CAD1CD5DCDB79397CAB35803F49B9A2E17557ED0A9A7BDA287D9B7A859143C578ACAEBAB328FE4987976F08ED35BC4C2899F76DFCC9EAB71CBB1FFC400281001000202020202020105010100000000010011213141516171108191A1C12030B1E1F0D1F1FFDA0008010000013F21135C41FF004712A54AF92A54A952A54A952A57C95FD02A57C07FC9C32A5422DD7C2A57C3CA354E743178C9D1659BEB2986477823D33DE488233AA537D0616D6657CA0D4B57AB9F9604A958AC5EA61171D48B01191B72604A7136A235A1781843EACBE5982CBE9590CF2394420A0FA4A4FECCFC6E3A0B77BE67D2EF59DCB0E0F70B69528C0F9352CEF31CDBD73A95A1DC1A37B0A982379CBF328DAE3AFF00597C51C1C3EE3449E6B5FB970D1F52F97F888B89463DBEF26030C5B846739A6E0851C02EAB3154006E5DAB17BCCBAB811CD16D730145E7133CC86AE3564332CA3755782C8863C07B9B172AC3170A6BC5371FEFA08422FECB969A5DB51191E87296330AEE71761C19C46E4B4AC45687A4C5B47B95F6995F8AB435ED2E765868C67D4FA1C5825B29B744F33172E86AEAE1E985798ABBAA2CCAA620D702E1993753845400234D25E9BA8931B91A0FBFDCAE5D222F7A85CE5C0B3CE3138D071C1C4050B8E840AE261BD2CD57DDC7ED1B65AF4EA282CE79F6CFF0CA43C6F32BCDB981584B409FAEA5E2357902FC4A5560DB8F234FC17A3D351863469C0C9B13B8DDFF0010574F8B8CB8462311771CD6A0E54F5716607D94A137BDA113AF2182636C764A55F028536FE59FFDD9D5F29E46488D385453C82CD39D444E72E6F307DBD329B982615732CC638F9640E2676CB458BAE456009716086CC47CF125FC0C2CBFA1E1F31B1E1F1528A6EE2AC39799695370BE3ED1ACD988B657C82AB6D4A2553934EA66E3DD28776A748A7CFA971E666B93E4C9B4A201C391EE0DAA851C47F97A8EC721E277F51F8BFA62AB8BC5CB610AF7346A2EF105302CEE68D0BCB99537ADFD32C51435EE21A33915D1FA6605240555BE661C6FC8848B977C6E49BC4FF022511DB006E156053184C3DB11B7547BD453761D8C4657DD4A1D65D38169D97D4D943E47C66D1E664A5FA4BACAB2C25A7B9262FE9E2083D26D96398B01CD6082E981458D323E4EA0368625A2FA3F1679F8602653932E726A23715FA1154D3EE5B4D69E62D56FF037BF5F2F1136AAB97894164BA68B620517D86A347AFF0048E6A53F02C12914BA0967C15FAF115986E260F5413C43712C75329534B2C4021E1D97067F047ECC7D41E467AC421C5BD4B2CAD7C2A5A2EEF0BEE505175463F22416E6D6B9F502DA332B979E66046985A8AE11484731426DC9DCC860F3028C54240BFCC4E04950DD6D38995A9BEC23EAAE5F97044CF83C6E604BCE572CB71A518CA5A949E0D4BEABC6605B38BA3E1980BC0B8B07920BB9DA533BB42D65A8712CD3E41339EC748CB5605820CC0FBBB826894EAB9988FF0031C8EAA34C28618D5D5C3CB03095B74F705DD15F44213B3C2E895DABCE348E35A2EA1DB5FF0052BCBF898103830D9F60E7E2C82EB8798742F656451391A81EACCAAE28A03E1931A710378FF3189A8B2F750ED1E497FF001984B482F61532C517A8937713FC98337981CD13846B2EC7C4071BC9E8943D207FE421435E949A345F29A8485D8B2AC5348D5E9855E6E710A95F8F1F0FF132A8D0567F625A94A2478AA0F750173567E578427570ACEA5C0B519245AC063290DE0F0CCF36E593728A582A2695B6A29C2545C776C71D4B0063A45979A2BC251ADDF64A36D9E0CA308FBB2E59BA0F0B3DA2A7FF005F1FAAC767B8F1894E4C1BADEA505991AFF64C78CC0D2F9CF1281A089A77911C62FC6F0CC20FE6696662B0862238678B63C4A6BC78B88DDAFC43FF0073B94E261E083D3D039FDCBB59F3B97AD8F62FE33629935B8B155E2A16F2946E62936D37844DD637DC1179DF377F728C5DC52A9C0398E78A7C47153E08833A88343E13376AC1C5EE59716EF48CEA96C66117EC12CECF116D34FAA8128BF43F73FDE524056BF12FF898E89DAA6B14AC87040793BA81048343FC4D96E73C7A8E982F72FA279432E5C0C56E038C4907308084F08B7A31A4C1C1731AA034C6E64C23E2380FD1B9470F124FA6A6EE2344F96C46296715F915353220E5094AFD4AD572B2D72CA52D933B968CB5BF1300C9E46DBCC56F071F10DD6AF6CF70A25C19714450CB59BFF0A8F70F112DBF501DCEC498850D033F98AC29D2C7C546DEAC6B98FCAB8B800C28BBFE63D0382E3B551CAE2686E409EC4709C0DCBE1F0FF40FC54E62EA7737E9500B06F6892EE73C054ACBA74839C757C25E1AA8A4C2F6C0C407F24BBAA72751190F572C563851155EC52FC4BCC3FACF8766687A63561FBCB59F084654A8EB146F8A9E44C4BD81DD7FA8CF743F982E30460F71B233E2225780D4A9421B2261620DA37370FEB212A136372908332EFD08610CAFDCCEB07086970D71032D8693A88BFCD4DBE3E166B258E5235E6E0AFED1F06B11BED2EA58FB8D9CC5F88A6E846388687B8E604C18E2A5A0D551FBE1FD821F177F8A0E929CCBC6E53C452E9E662250DFCC4C70FEC939F816775A7733BFD288BABB8A0D245789FFDA000C030000011102110000108BB65D5F6C9081A6A235F8CC97797C63D2ED9B666BDD63F5598DAB438284EBB23D1E8853BFD8F96A38A8488F3E263D6AE86605BE76D614C0AA1E94A617FF00FBBB139C212FEAF165FB50DAE9EC5385CBB83BE3F6FD1B6A3E3CD9C3F67C102C7C03AB2F92D3E1668C20EAD08A0FC62D209C35CFF2BBB50335CD4EF3CF3D54D9C7FFC4002011010101000202030003000000000000000100112131104120516171E1F0FFDA0008010211013F103F100A3745F9C9765AB509D5F8DB24A0D3840E9270B0F5718162240F64139083C1BAF5616A8FABA94F2F8016FAB2624BED5938A90FF4948ABB028F217EAEA16B34F09A3D4DFC6C89C127E1E7651B0156E46D0B080E267290BE160F01F06513099B2773832E116E53D6CCCC9382DD2D0FD6D87C6E8F711870EE2408582C1451D2B1B1E89D916FE42EAD63B9641DCEEF139D25687883ED09615FB461EEFB2C7A88CBD5640E6D80D7B82E4E7C1D32AF70247601EBC75E10763905DE4B1FEEE52E622D7AF80018C8F1A058ABE1383E1BB8BBFEF53ADF8EFCCCE3CF10FD21E081258CF9E43F60B26813ECBD2392E2DBF239E22FFFC4001E110101010002030101010000000000000001001121311041512061A1FFDA0008010111013F105F9BF13EE6FEF09D3E743B6FEF7213CBBBE883C5B9DDAE9B4EAFAB6374CB70B364E03DC07425ED1D80E099CA1EE65C8B8B031CA07FB0BD3FD8F93FD813317F143C4705EE0F85DBDDEC4321AAE6BDDEFCF4F87D5F6544CC8A6F71C3C6F5078C8046C1ACB82750FBCB71B65BB726963CA0585A9F5F8C873718F0CDC62704F01884DC70956FD8CBCB2E93905EA2D6C69A5C9032491E11B9EC4DCF8E20CE39B1481D484D3C0FBF001D4CF497A07BB8B86D2403D2C906619463892B7D7CB203243B8C1D8C6F8843A5D1DE4B9308867E72123DD00E1944773DE4CB896F3FBDE091C9908E23AF867374FD3E23A2D6FFC4002810010002020105000104030101000000000100112131415161718191A110B1C1F020D1E130F1FFDA0008010000013F10A80D0E93759B6FCE78FF00E1909F19E33C7F49FF008E47C22A311957557EB6B5818759F22CD8FCFD3E30B688A3806ADC4ED9F41F971526829FBAD8531F109FDD751A10EC3FEB6A0484362D7E6381871603ECBFCC567BB59FDE50BA0EA37FAC24B06A759241781B63186EA1F4D4498824D9F009531654AC0DA026823F7222803C011057374B8E874F7711912A88EB4156426B88B95CB179883C1B4B00EEAE232BAEC053CE3389A87D4437C5D4B52CC809F7387D41548D919DD5BB9430366C3BB2769686CA06B653DFD4A147965337D37CC01980B0367C710BABE273A7A7FD8E839980D879981C36132F7CCA750EFF0008660E702F11F0C3F265DC5D14BD33A4C94B03629A5FDC04BF3A37BDA5BB81BDB76BB63AFF00B8ACF9669CAB98400B72BAB00D2616D5F3085551E17856B06F4B080CA1343377F3989DAA28509D28DEAF30B1215ACD7597DB1B4ACD6BD7B882148E6AF1C7DDC67A92948F31B8A700961D57960CF05831AE52F52C42B4790F2CCC8522D4EB045F61838FE0CBACBC381746667154CD3E272410FA15F3E6568019668F5EB348865643DDDC1F3823507557172C4A4526CD7781B4F35367788AE5014B1ECC55B11C12CA7B90FA9E6F7C73B84B1086E606481B34F245B640AD0D803028DF7BA960A5863078967F9239C057656BDD544B9334AED6C2C60E4A2F388946B28810EEE8F5070EF2AE659E45DEA2E25898AE19C82AD62DE1E97D6357DB1A82E44E7DEE039B631BAE8DE7FF00B1168F92482357558574A8A1B22C1572587AA9ABFB05DB17138AA0A2D3F7A41DA9B0072B6345E1E21E126841CE819CE2B70636AA3BDB23A9D6C9749351CB472A3072FA8933E6C54D27081757D291C4AB16EAB085944C56C4B97E224EA47C285FCC75DD5A0C1CA2D38B9853DA3734915EDDC90CEA1334BD415380B645C3A65E039DC536F9FF00D3CBB58B7972F7975B894B730452710C3C88D435DC960BC827910C427156B7A5C7B89C19DB1E90807F45DA6E08B56CFE014CC8ABF3F016A2ABC5C36BFDE1C2BD85BFB3840EF966ED7599282ADDE72C461EB414AD2BD49962C9D5B93307227681CCAB520AE6A163DC65809CED65194EE4A2E8BE544142EFAD4BDBEA1ADC36F50CEE136B0A5690060B07BFE63B9AD82AC4717F2538B89C67B41562391C91204A57D69FB3109F52D22BE80E8CA7A02A8B2FCF89B007634A7894E9E232B3D4D63A653211272DBAE1DA145A475AF7539FABE9896AB9665B6E07A67A3E2C932482E04B1F7B87915A2568982B59C915685A9A69234B5474BA60DA0DD8764BFD195041DD831126BDBAF888D051424BFB0398864C75987CCD69FB2BC1E9D63645ECE16D1E69DF486BA6D41559DADCC479428BDDF357B89222EA553E4AD835A0525AA3689AA81A86AD697FE98065EBA5C53406F78972C8757EA20A0004410E901B7B78A1EA3D7BCCC2E5655B2BDE0565783445A956344DF64B0E9DA5A2ACCC00B61FCDE59D7823EC98BAC2805F5398C97074C4E861C0B80A822F142161579F1166FB3417F118B746AD43D15FB4B6B056542A7F7C4C82164190EF2B989C027BC6E554367A56AE8F352CB32612BFDD97950E840F36DCB0B556ADFC57E635129D87396291841616F4661CA768C022DA966A29402A71749F63D1574045029D9845B7A8E8BCEE64CC38C4A7D399651D58E667A0168B66FEEFDCE105420D44C0ADB6BE1191528B5ABF517121FE981AD57C58A3CF4878824962DEC154377F8862E0EABE95B80B58AA4FC0331A696618FEF68A82999B5723D331795791D936B7300D5CB6B4A1DAC14EB186423A76B55EF14E4A2E88301A85611EB065287BDC08101684185456090A88C1217D8CE5F40CC1FCAB4E18A942440B7268FB04D2AA39B5F584386800512638E70AB9C1E3790B7E2E7D8C921AC0137AB18A91DEC164ED7510370ABC04EE6087D66AE2870E61C9461B2ABCC5CD3046076968EB0A9D4C83A0F3B89529566C8B941B070F243C13DA3729CA01C295380A5E6CB0EB565A4DBE2702164AFF00682511A21560235C62582BC6DAA247F760D689AB69F58D01E4AE278D4ACD601667BBAAF103979260F185966D16D0147EB515C4295BBAF32A16A541A23CACD78EB05F42C8ACEC314A91B71D840D46003980783866AE462BCA3082D452C074D8E331F9D80F7D26045329A5E606D4E06E9DA3DBEB906A6FCDB0AD262228A2DA03314D8101D104351CEB32DB34634A5DC306CB0B60A1F7BF7114588C3632780FAB3500C1B01DB85ED140A0C06CF9CC518359308F2AEA5C1E4A87FA8F54D0AA9F32A1B8AAA2AF777125761B2EA1658C3D3165C4E4550C46B6B90E12B93A90AA810054D60B3DC35B4065DE9971E0F72B5316A506387175AEB71F0500E8252AFD4AB4814268F3D621A54817C671D25C2670C5BB61E14144DD29925E18D62A5C050BB724A12815B5F3182E0BB18496AC79A3A0F310051A5C4DAFC9401E66F17C5A0CDCAB63D8FF0051258650B01F76C4C4749F048A05ACB067CD46D2C4D613F23021C1292CABDC66079FE425BD631DA9F8318ACC023490157554C9653187B1DD433863051D29DC46ED0B2B473499D633F621FA2D01468AF5FC40054A53F62DDC6735EE0077395B8A5DAB56B310A8B22AF8CC668B46AB771468CDB5AED182FA285D37A9A20D458DC5C8B0451E5FCA24A2F522EF7A5FB2F5006A874F4D41F4272A37F0458EC82552B1D8CDCB1A3305AFEFA9B240CA53E122AA62DC7F21169F289D65C11530168CAED69C90AB8EAD0CDFDD3D62B0AB8C1471A362B399D42BDE5E557ACBC1B466D899BE8C4C2E5906723A9554DDF625182D6F8116434980EBCBC44DBCD4037EDEEC2B4EDA4A1B453985396BBDF7F6AA0DB36CB5F9A86E0E6803F6541F068500F5B9C2166CC7AB7E25FC2302B0FD9FB2E53B0DEFB06997051A107B2F22F1092D69BAC7C46446CCB5DD0E7A0FB9C12E90A561A4CA6B89713C76342E17558D5639991A5BBD1FDC4194874DC08C321DFF00F51C2A4D5637518B069AA951B55C30AB386EE21B34A9B60F9844A58F8BA8DA5D29C27ED078505502817A60A2551181F48E65E5D5C52FD9555BEAA37EA07C8AC54FF38996D76937C4BCB07A657CC45040BDF1FC3DCA13FAC09B824E4B260F9892A5AAAC1846B96B5A600734D013A9D09C6A0B1B6EB296B35E2E97A4B518388111BC8C8034DFBBFC4744452C2F04260206693057E63F73D0B8979F4116B388262025C6D5709C315219100F6ED41F71D206042115D9A79D4BFB2B4FD87E66F8D7C2348A58B6FC8C363C8807A40E11C5C7D4EC98D4BB550F9C92881F282BA5B8B9802C05C829A1DE53B36252D2DF0463C814D376C2E10A029A39C1C5462C95C532954BC9C5FF00A82163C4A0371232F28EC4A5CAABFAC5A25DFD12DFA39057B2B77335A5A5BBE7F944A8E1D598D53B4553F30E9D17F705C085214EA3B0815E7A50FC308088580073BFC4537C57A51DF8FF00B093B6AB767426CE1606C710C74CCB20C2E872FE90405789719EEFF10C196C4E657938BA86AF6445883DF69BEEC52E0C194471C44C3803B41C7D8295BD41FBC1A29AA41E6C8437CC8763C989783544B095076C355E98B2A9D62AB6DC6BAB4A7AAE630B58A0942F6882A2DCADFA3C90C38055BDFE277400183FDB0489A97C88CDD57965EF2AC1D656332FFC08A2A8154DACCA2844ABBCA87EC7315C84FCC756467F60E21131C04AFB0CDE6161FBA3A962758EFAC5458A6D67294AAC551AD654580D21613A10BA199F1E0856A355D65D01FDB36576B308B2BFC2E2638A9B08792392402597BCCA4454DC8466AA1C6C442D247DF92529F6BB1FB2D9AAA82E0746A9BB5EF19BB63E333E751DA0AA51A6F5EB0D065E86575AE1572C00DE2FC7E95D3DC7FC07F423CC529321BAC8E33F25BC201E907A8257BB3A89688C036B780494222ADDED6645DE99F81073882FAE624236660840B0742F596468AB29567D7F477CCFB3ECFB097163DCDA3C625D0D96BEC0176AF10A3147AD407027789E4D9D26EA8DE616557599A59DC1BFCC10A6F13259BAA68EC455931DC67897FE6B7F60C3D4A0557565B5622EE6FF00866649471647143B932ACD4FFFD9)
SET IDENTITY_INSERT [dbo].[TB_MAE_CategoriaMenu] ON 

INSERT [dbo].[TB_MAE_CategoriaMenu] ([MCAT_Codigo], [MCAT_Nombre], [MCAT_Token]) VALUES (1, N'General', N'7414aa4e-c330-49b5-85dd-d065b57dd08d')
INSERT [dbo].[TB_MAE_CategoriaMenu] ([MCAT_Codigo], [MCAT_Nombre], [MCAT_Token]) VALUES (2, N'Adminisración', N'e76cb09e-2f32-4e3b-8201-89794d1ea1cf')
SET IDENTITY_INSERT [dbo].[TB_MAE_CategoriaMenu] OFF
SET IDENTITY_INSERT [dbo].[TB_MAE_Entidad] ON 

INSERT [dbo].[TB_MAE_Entidad] ([ENTI_Codigo], [ENTI_TIEN_Codigo], [ENTI_Token], [ENTI_FechaCreacion], [ENTI_Identificador]) VALUES (1, 1, N'57619efc-0836-429a-bb0f-5ee99a0f529d', CAST(N'2015-09-24 17:27:35.060' AS DateTime), N'Root (Administrador)')
INSERT [dbo].[TB_MAE_Entidad] ([ENTI_Codigo], [ENTI_TIEN_Codigo], [ENTI_Token], [ENTI_FechaCreacion], [ENTI_Identificador]) VALUES (36, 2, N'ad4bad92-554f-4e0e-aee5-9361153c7470', CAST(N'2015-11-04 02:12:46.920' AS DateTime), N'dmunozgaete@gmail.com')
INSERT [dbo].[TB_MAE_Entidad] ([ENTI_Codigo], [ENTI_TIEN_Codigo], [ENTI_Token], [ENTI_FechaCreacion], [ENTI_Identificador]) VALUES (37, 2, N'7788da93-f276-4da4-82b1-231b338bb983', CAST(N'2015-11-04 12:06:01.747' AS DateTime), N'ligia.alcayaga@gmail.com')
INSERT [dbo].[TB_MAE_Entidad] ([ENTI_Codigo], [ENTI_TIEN_Codigo], [ENTI_Token], [ENTI_FechaCreacion], [ENTI_Identificador]) VALUES (38, 2, N'88349ca2-5e62-4a04-b844-e2193301b1cc', CAST(N'2015-11-04 12:14:46.223' AS DateTime), N'jonathan.ancan@gmail.com')
INSERT [dbo].[TB_MAE_Entidad] ([ENTI_Codigo], [ENTI_TIEN_Codigo], [ENTI_Token], [ENTI_FechaCreacion], [ENTI_Identificador]) VALUES (39, 2, N'1a76b599-267b-4d55-8254-ef69de52036a', CAST(N'2015-11-04 12:24:25.430' AS DateTime), N'cgutierrez@valentys.com')
INSERT [dbo].[TB_MAE_Entidad] ([ENTI_Codigo], [ENTI_TIEN_Codigo], [ENTI_Token], [ENTI_FechaCreacion], [ENTI_Identificador]) VALUES (40, 2, N'be05140e-32f8-418e-8119-bf07e2689576', CAST(N'2015-11-04 12:28:51.663' AS DateTime), N'aleshae@gmail.com')
INSERT [dbo].[TB_MAE_Entidad] ([ENTI_Codigo], [ENTI_TIEN_Codigo], [ENTI_Token], [ENTI_FechaCreacion], [ENTI_Identificador]) VALUES (41, 1, N'f0017f62-a15b-44aa-b2c9-150600f41cd0', CAST(N'2015-11-06 01:46:57.200' AS DateTime), N'Emabajdor (Emabjador de la APP)')
SET IDENTITY_INSERT [dbo].[TB_MAE_Entidad] OFF
SET IDENTITY_INSERT [dbo].[TB_MAE_ItemMenu] ON 

INSERT [dbo].[TB_MAE_ItemMenu] ([MITE_Codigo], [MITE_MCAT_Codigo], [MITE_Nombre], [MITE_Url], [MITE_Icono], [MITE_Ordinal]) VALUES (2, 1, N'Indicadores', N'app.home', N'action:trending_up', 1)
INSERT [dbo].[TB_MAE_ItemMenu] ([MITE_Codigo], [MITE_MCAT_Codigo], [MITE_Nombre], [MITE_Url], [MITE_Icono], [MITE_Ordinal]) VALUES (4, 2, N'Compañias', N'app.company', N'communication:business', 2)
SET IDENTITY_INSERT [dbo].[TB_MAE_ItemMenu] OFF
INSERT [dbo].[TB_MAE_ItemMenu_Perfil] ([MENUPERF_PERF_Codigo], [MENUPERF_MITE_Codigo]) VALUES (1, 2)
INSERT [dbo].[TB_MAE_ItemMenu_Perfil] ([MENUPERF_PERF_Codigo], [MENUPERF_MITE_Codigo]) VALUES (1, 4)
SET IDENTITY_INSERT [dbo].[TB_MAE_LogError] ON 

INSERT [dbo].[TB_MAE_LogError] ([ELOG_Codigo], [ELOG_ENTI_Codigo], [ELOG_Tipo], [ELOG_Pila], [ELOG_Fecha]) VALUES (1, 36, N'DBERROR', N'PA_MOT_UPD_CompartirRuta: Cannot insert the value NULL into column ''RUCO_Observaciones'', table ''MotoApp_v1.dbo.TB_MOT_RutaCompartida''; column does not allow nulls. INSERT fails.', CAST(N'2015-11-04 22:25:31.570' AS DateTime))
INSERT [dbo].[TB_MAE_LogError] ([ELOG_Codigo], [ELOG_ENTI_Codigo], [ELOG_Tipo], [ELOG_Pila], [ELOG_Fecha]) VALUES (2, 36, N'DBERROR', N'PA_MOT_UPD_CompartirRuta: Cannot insert the value NULL into column ''RUCO_Observaciones'', table ''MotoApp_v1.dbo.TB_MOT_RutaCompartida''; column does not allow nulls. INSERT fails.', CAST(N'2015-11-04 22:25:50.497' AS DateTime))
SET IDENTITY_INSERT [dbo].[TB_MAE_LogError] OFF
INSERT [dbo].[TB_MAE_Perfil] ([PERF_Codigo], [PERF_Descripcion], [PERF_Identificador]) VALUES (1, N'Perfil Administrador', N'ROOT')
INSERT [dbo].[TB_MAE_Perfil] ([PERF_Codigo], [PERF_Descripcion], [PERF_Identificador]) VALUES (41, N'Perfil de Embajador', N'EMBA')
INSERT [dbo].[TB_MAE_Perfil_Usuario] ([PEUS_USUA_Codigo], [PUES_PERF_Codigo]) VALUES (36, 41)
INSERT [dbo].[TB_MAE_Perfil_Usuario] ([PEUS_USUA_Codigo], [PUES_PERF_Codigo]) VALUES (37, 41)
INSERT [dbo].[TB_MAE_Perfil_Usuario] ([PEUS_USUA_Codigo], [PUES_PERF_Codigo]) VALUES (38, 41)
INSERT [dbo].[TB_MAE_TipoEntidad] ([TIEN_Codigo], [TIEN_Identificador], [TIEN_Nombre], [TIEN_Descripcion], [TIEN_Token]) VALUES (1, N'PERF', N'Rol', N'Entidad de Tipo Rol, sirve para otorgar niveles de acceso a un actor de sistema', N'ad772427-df93-455a-b4be-5a79d6272e3a')
INSERT [dbo].[TB_MAE_TipoEntidad] ([TIEN_Codigo], [TIEN_Identificador], [TIEN_Nombre], [TIEN_Descripcion], [TIEN_Token]) VALUES (2, N'USUA', N'Usuario', N'Entidad Actor del sistema', N'86b67efc-cc59-4b87-8631-162e91de98b8')
INSERT [dbo].[TB_MAE_TipoEntidad] ([TIEN_Codigo], [TIEN_Identificador], [TIEN_Nombre], [TIEN_Descripcion], [TIEN_Token]) VALUES (3, N'COMP', N'Compañia', N'Entida representativa de una compañia', N'f415ddf2-7bdf-4714-a5a7-1599c5294171')
INSERT [dbo].[TB_MAE_TipoEntidad] ([TIEN_Codigo], [TIEN_Identificador], [TIEN_Nombre], [TIEN_Descripcion], [TIEN_Token]) VALUES (4, N'INSP', N'Usuario Inspector', N'Usuario Inspector', N'888d8257-d036-4e2f-b8fe-37aabf2c01dc')
INSERT [dbo].[TB_MAE_Usuario] ([USUA_Codigo], [USUA_ARCH_Codigo], [USUA_Activo], [USUA_UltimaConexion], [USUA_Email], [USUA_NombreCompleto], [USUA_TIDE_Codigo]) VALUES (36, 1046, 1, CAST(N'2015-11-04 02:12:46.920' AS DateTime), N'dmunozgaete@gmail.com', N'David Antonio Muñoz Gaete', 100)
INSERT [dbo].[TB_MAE_Usuario] ([USUA_Codigo], [USUA_ARCH_Codigo], [USUA_Activo], [USUA_UltimaConexion], [USUA_Email], [USUA_NombreCompleto], [USUA_TIDE_Codigo]) VALUES (37, 1047, 1, CAST(N'2015-11-04 12:06:01.747' AS DateTime), N'ligia.alcayaga@gmail.com', N'Ligia Alcayaga Madrid', 200)
INSERT [dbo].[TB_MAE_Usuario] ([USUA_Codigo], [USUA_ARCH_Codigo], [USUA_Activo], [USUA_UltimaConexion], [USUA_Email], [USUA_NombreCompleto], [USUA_TIDE_Codigo]) VALUES (38, 1048, 1, CAST(N'2015-11-04 12:14:46.223' AS DateTime), N'jonathan.ancan@gmail.com', N'Jonathan Ancan', 100)
INSERT [dbo].[TB_MAE_Usuario] ([USUA_Codigo], [USUA_ARCH_Codigo], [USUA_Activo], [USUA_UltimaConexion], [USUA_Email], [USUA_NombreCompleto], [USUA_TIDE_Codigo]) VALUES (39, 1049, 1, CAST(N'2015-11-04 12:24:25.430' AS DateTime), N'cgutierrez@valentys.com', N'Claudio Alejandro Gutierrez Olave', 200)
INSERT [dbo].[TB_MAE_Usuario] ([USUA_Codigo], [USUA_ARCH_Codigo], [USUA_Activo], [USUA_UltimaConexion], [USUA_Email], [USUA_NombreCompleto], [USUA_TIDE_Codigo]) VALUES (40, 1050, 1, CAST(N'2015-11-04 12:28:51.663' AS DateTime), N'aleshae@gmail.com', N'Alejandro Shae', 100)
INSERT [dbo].[TB_MOT_AutenticadorExterno] ([AEXT_USUA_Codigo], [AEXT_Identificador], [AEXT_TIAU_Identificador]) VALUES (36, N'10153735708553259', N'fbook')
INSERT [dbo].[TB_MOT_AutenticadorExterno] ([AEXT_USUA_Codigo], [AEXT_Identificador], [AEXT_TIAU_Identificador]) VALUES (37, N'10153369001074234', N'fbook')
INSERT [dbo].[TB_MOT_AutenticadorExterno] ([AEXT_USUA_Codigo], [AEXT_Identificador], [AEXT_TIAU_Identificador]) VALUES (38, N'10207692267002934', N'fbook')
INSERT [dbo].[TB_MOT_AutenticadorExterno] ([AEXT_USUA_Codigo], [AEXT_Identificador], [AEXT_TIAU_Identificador]) VALUES (39, N'10153399483204565', N'fbook')
INSERT [dbo].[TB_MOT_AutenticadorExterno] ([AEXT_USUA_Codigo], [AEXT_Identificador], [AEXT_TIAU_Identificador]) VALUES (40, N'10153722963839393', N'fbook')
INSERT [dbo].[TB_MOT_ContadorSocial] ([SOCU_USUA_Codigo], [SOCU_Seguidores], [SOCU_Siguiendo], [SOCU_MeGusta]) VALUES (36, 0, 2, 0)
INSERT [dbo].[TB_MOT_ContadorSocial] ([SOCU_USUA_Codigo], [SOCU_Seguidores], [SOCU_Siguiendo], [SOCU_MeGusta]) VALUES (37, 1, 0, 0)
INSERT [dbo].[TB_MOT_ContadorSocial] ([SOCU_USUA_Codigo], [SOCU_Seguidores], [SOCU_Siguiendo], [SOCU_MeGusta]) VALUES (38, 1, 0, 0)
INSERT [dbo].[TB_MOT_ContadorSocial] ([SOCU_USUA_Codigo], [SOCU_Seguidores], [SOCU_Siguiendo], [SOCU_MeGusta]) VALUES (39, 0, 0, 0)
INSERT [dbo].[TB_MOT_ContadorSocial] ([SOCU_USUA_Codigo], [SOCU_Seguidores], [SOCU_Siguiendo], [SOCU_MeGusta]) VALUES (40, 0, 0, 0)
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (7, CAST(-33.408310000 AS Decimal(18, 9)), CAST(-70.551620000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-04 23:14:21.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (7, CAST(-33.408530000 AS Decimal(18, 9)), CAST(-70.550800000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(144.44005 AS Decimal(18, 5)), CAST(0.08028 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-04 23:14:41.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (7, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.549540000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(108.11268 AS Decimal(18, 5)), CAST(0.12025 AS Decimal(18, 5)), CAST(4.00400 AS Decimal(18, 5)), CAST(N'2015-11-04 23:14:45.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (7, CAST(-33.407450000 AS Decimal(18, 9)), CAST(-70.549680000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(110.48367 AS Decimal(18, 5)), CAST(0.09192 AS Decimal(18, 5)), CAST(2.99500 AS Decimal(18, 5)), CAST(N'2015-11-04 23:14:48.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (7, CAST(-33.406920000 AS Decimal(18, 9)), CAST(-70.549180000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(135.87171 AS Decimal(18, 5)), CAST(0.07556 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:14:50.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (7, CAST(-33.406820000 AS Decimal(18, 9)), CAST(-70.548560000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(105.02044 AS Decimal(18, 5)), CAST(0.05832 AS Decimal(18, 5)), CAST(1.99900 AS Decimal(18, 5)), CAST(N'2015-11-04 23:14:52.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (7, CAST(-33.406890000 AS Decimal(18, 9)), CAST(-70.548450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(24.29763 AS Decimal(18, 5)), CAST(0.01351 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:14:54.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (9, CAST(-33.408340000 AS Decimal(18, 9)), CAST(-70.553080000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 00:17:26.950' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (9, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.552450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(70.55192 AS Decimal(18, 5)), CAST(0.05873 AS Decimal(18, 5)), CAST(2.99700 AS Decimal(18, 5)), CAST(N'2015-11-05 00:17:29.947' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (9, CAST(-33.408310000 AS Decimal(18, 9)), CAST(-70.551620000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(137.94700 AS Decimal(18, 5)), CAST(0.07679 AS Decimal(18, 5)), CAST(2.00400 AS Decimal(18, 5)), CAST(N'2015-11-05 00:17:31.953' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (9, CAST(-33.408530000 AS Decimal(18, 9)), CAST(-70.550800000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(144.44005 AS Decimal(18, 5)), CAST(0.08028 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 00:17:50.960' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (9, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.550300000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(93.05789 AS Decimal(18, 5)), CAST(0.05175 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-05 00:17:52.960' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (9, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.549540000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(127.12995 AS Decimal(18, 5)), CAST(0.07063 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 00:17:54.960' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (9, CAST(-33.406920000 AS Decimal(18, 9)), CAST(-70.549180000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(135.93961 AS Decimal(18, 5)), CAST(0.07556 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 00:17:58.963' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (9, CAST(-33.406890000 AS Decimal(18, 9)), CAST(-70.548450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(24.27338 AS Decimal(18, 5)), CAST(0.01351 AS Decimal(18, 5)), CAST(2.00400 AS Decimal(18, 5)), CAST(N'2015-11-05 00:18:02.970' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.408060000 AS Decimal(18, 9)), CAST(-70.555090000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:09.107' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.408140000 AS Decimal(18, 9)), CAST(-70.554220000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(145.55138 AS Decimal(18, 5)), CAST(0.08086 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:11.107' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.553690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(92.29427 AS Decimal(18, 5)), CAST(0.05127 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:13.107' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.408340000 AS Decimal(18, 9)), CAST(-70.553080000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(102.14565 AS Decimal(18, 5)), CAST(0.05683 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:15.110' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.552450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(105.61643 AS Decimal(18, 5)), CAST(0.05873 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:17.110' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.408310000 AS Decimal(18, 9)), CAST(-70.551620000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(138.15382 AS Decimal(18, 5)), CAST(0.07679 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:19.113' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.408530000 AS Decimal(18, 9)), CAST(-70.550800000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(144.22382 AS Decimal(18, 5)), CAST(0.08028 AS Decimal(18, 5)), CAST(2.00400 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:37.130' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.550300000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(93.10439 AS Decimal(18, 5)), CAST(0.05175 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:39.133' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.549540000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(127.12995 AS Decimal(18, 5)), CAST(0.07063 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:41.133' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.407450000 AS Decimal(18, 9)), CAST(-70.549680000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(165.28400 AS Decimal(18, 5)), CAST(0.09192 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:43.133' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.406920000 AS Decimal(18, 9)), CAST(-70.549180000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(135.93961 AS Decimal(18, 5)), CAST(0.07556 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:45.137' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.406820000 AS Decimal(18, 9)), CAST(-70.548560000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(104.86307 AS Decimal(18, 5)), CAST(0.05832 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:47.137' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.406890000 AS Decimal(18, 9)), CAST(-70.548450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(24.32193 AS Decimal(18, 5)), CAST(0.01351 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:49.137' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.406980000 AS Decimal(18, 9)), CAST(-70.548350000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(24.11151 AS Decimal(18, 5)), CAST(0.01340 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:51.137' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.407460000 AS Decimal(18, 9)), CAST(-70.548000000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(56.31498 AS Decimal(18, 5)), CAST(0.06260 AS Decimal(18, 5)), CAST(4.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:55.140' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.407740000 AS Decimal(18, 9)), CAST(-70.547990000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(55.75731 AS Decimal(18, 5)), CAST(0.03098 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:57.140' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.407980000 AS Decimal(18, 9)), CAST(-70.547870000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(51.45497 AS Decimal(18, 5)), CAST(0.02859 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 06:04:59.140' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.408050000 AS Decimal(18, 9)), CAST(-70.547310000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(93.68628 AS Decimal(18, 5)), CAST(0.05207 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:01.140' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.407920000 AS Decimal(18, 9)), CAST(-70.546690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(108.30438 AS Decimal(18, 5)), CAST(0.06023 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:03.143' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.407920000 AS Decimal(18, 9)), CAST(-70.545880000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(134.81171 AS Decimal(18, 5)), CAST(0.07497 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:05.143' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.407650000 AS Decimal(18, 9)), CAST(-70.545030000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(151.75652 AS Decimal(18, 5)), CAST(0.08444 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:07.147' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.406810000 AS Decimal(18, 9)), CAST(-70.544400000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(196.83981 AS Decimal(18, 5)), CAST(0.10968 AS Decimal(18, 5)), CAST(2.00600 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:09.153' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.406710000 AS Decimal(18, 9)), CAST(-70.544290000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(26.67241 AS Decimal(18, 5)), CAST(0.01483 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:11.153' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.406440000 AS Decimal(18, 9)), CAST(-70.543600000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(127.82841 AS Decimal(18, 5)), CAST(0.07109 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:13.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.406330000 AS Decimal(18, 9)), CAST(-70.543380000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(43.15402 AS Decimal(18, 5)), CAST(0.02400 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:15.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.405780000 AS Decimal(18, 9)), CAST(-70.541940000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(263.45073 AS Decimal(18, 5)), CAST(0.14658 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:17.160' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.405540000 AS Decimal(18, 9)), CAST(-70.540720000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(209.80212 AS Decimal(18, 5)), CAST(0.11662 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:19.163' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.405290000 AS Decimal(18, 9)), CAST(-70.539180000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(261.82698 AS Decimal(18, 5)), CAST(0.14546 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:21.163' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.404630000 AS Decimal(18, 9)), CAST(-70.537900000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(251.80361 AS Decimal(18, 5)), CAST(0.13996 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:23.163' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.403240000 AS Decimal(18, 9)), CAST(-70.536960000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(320.10770 AS Decimal(18, 5)), CAST(0.17793 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:25.163' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.403190000 AS Decimal(18, 9)), CAST(-70.536900000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(12.61286 AS Decimal(18, 5)), CAST(0.00701 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:27.167' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.403100000 AS Decimal(18, 9)), CAST(-70.536810000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(23.23005 AS Decimal(18, 5)), CAST(0.01291 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:29.167' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.401830000 AS Decimal(18, 9)), CAST(-70.536020000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(287.33650 AS Decimal(18, 5)), CAST(0.16011 AS Decimal(18, 5)), CAST(2.00600 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:31.170' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.399940000 AS Decimal(18, 9)), CAST(-70.535050000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(409.25861 AS Decimal(18, 5)), CAST(0.22771 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:33.173' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.398920000 AS Decimal(18, 9)), CAST(-70.533810000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(290.67189 AS Decimal(18, 5)), CAST(0.16157 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:35.177' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.398610000 AS Decimal(18, 9)), CAST(-70.532550000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(219.67862 AS Decimal(18, 5)), CAST(0.12229 AS Decimal(18, 5)), CAST(2.00400 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:37.180' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.398610000 AS Decimal(18, 9)), CAST(-70.531920000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(106.18182 AS Decimal(18, 5)), CAST(0.05902 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:39.180' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.397510000 AS Decimal(18, 9)), CAST(-70.531390000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(234.99999 AS Decimal(18, 5)), CAST(0.13069 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:41.183' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.396160000 AS Decimal(18, 9)), CAST(-70.531360000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(270.11093 AS Decimal(18, 5)), CAST(0.15014 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:43.183' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.394940000 AS Decimal(18, 9)), CAST(-70.531350000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(244.72980 AS Decimal(18, 5)), CAST(0.13610 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:45.187' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.393620000 AS Decimal(18, 9)), CAST(-70.531030000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(268.12721 AS Decimal(18, 5)), CAST(0.14941 AS Decimal(18, 5)), CAST(2.00600 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:47.190' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.392530000 AS Decimal(18, 9)), CAST(-70.530210000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(258.13966 AS Decimal(18, 5)), CAST(0.14341 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:49.190' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.392460000 AS Decimal(18, 9)), CAST(-70.530040000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(30.26650 AS Decimal(18, 5)), CAST(0.01685 AS Decimal(18, 5)), CAST(2.00400 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:51.197' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.392440000 AS Decimal(18, 9)), CAST(-70.529910000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(23.04341 AS Decimal(18, 5)), CAST(0.01283 AS Decimal(18, 5)), CAST(2.00500 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:53.200' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.392150000 AS Decimal(18, 9)), CAST(-70.529120000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(71.69186 AS Decimal(18, 5)), CAST(0.07978 AS Decimal(18, 5)), CAST(4.00600 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:57.207' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.392640000 AS Decimal(18, 9)), CAST(-70.527820000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(238.70009 AS Decimal(18, 5)), CAST(0.13281 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-06 06:05:59.210' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.394520000 AS Decimal(18, 9)), CAST(-70.528290000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(384.85375 AS Decimal(18, 5)), CAST(0.21391 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:01.210' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.394610000 AS Decimal(18, 9)), CAST(-70.528290000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(18.27596 AS Decimal(18, 5)), CAST(0.01016 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:03.210' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.396130000 AS Decimal(18, 9)), CAST(-70.528490000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(305.48868 AS Decimal(18, 5)), CAST(0.16989 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:05.213' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.397430000 AS Decimal(18, 9)), CAST(-70.528490000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(260.31763 AS Decimal(18, 5)), CAST(0.14477 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:07.217' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.398300000 AS Decimal(18, 9)), CAST(-70.528480000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(173.75475 AS Decimal(18, 5)), CAST(0.09672 AS Decimal(18, 5)), CAST(2.00400 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:09.220' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.398440000 AS Decimal(18, 9)), CAST(-70.528480000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(26.71038 AS Decimal(18, 5)), CAST(0.01485 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:11.220' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.398950000 AS Decimal(18, 9)), CAST(-70.528690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(107.85179 AS Decimal(18, 5)), CAST(0.05998 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:13.223' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.400250000 AS Decimal(18, 9)), CAST(-70.528890000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(262.80392 AS Decimal(18, 5)), CAST(0.14622 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:15.227' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.401680000 AS Decimal(18, 9)), CAST(-70.528880000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(285.20374 AS Decimal(18, 5)), CAST(0.15860 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:17.227' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.402580000 AS Decimal(18, 9)), CAST(-70.527270000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(323.42962 AS Decimal(18, 5)), CAST(0.17995 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:19.230' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.402750000 AS Decimal(18, 9)), CAST(-70.524560000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(454.01652 AS Decimal(18, 5)), CAST(0.25248 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:21.233' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.402910000 AS Decimal(18, 9)), CAST(-70.520200000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(728.50522 AS Decimal(18, 5)), CAST(0.40533 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:23.237' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.403330000 AS Decimal(18, 9)), CAST(-70.516980000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(543.02460 AS Decimal(18, 5)), CAST(0.30198 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:25.237' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.401940000 AS Decimal(18, 9)), CAST(-70.516350000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(204.77773 AS Decimal(18, 5)), CAST(0.16581 AS Decimal(18, 5)), CAST(2.91500 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:28.153' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.399560000 AS Decimal(18, 9)), CAST(-70.516140000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(429.00426 AS Decimal(18, 5)), CAST(0.26551 AS Decimal(18, 5)), CAST(2.22800 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:30.380' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.397540000 AS Decimal(18, 9)), CAST(-70.515260000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(276.90450 AS Decimal(18, 5)), CAST(0.23852 AS Decimal(18, 5)), CAST(3.10100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:33.483' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.395870000 AS Decimal(18, 9)), CAST(-70.514950000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(117.15111 AS Decimal(18, 5)), CAST(0.18803 AS Decimal(18, 5)), CAST(5.77800 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:39.260' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.395720000 AS Decimal(18, 9)), CAST(-70.514900000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(21.62560 AS Decimal(18, 5)), CAST(0.01767 AS Decimal(18, 5)), CAST(2.94200 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:42.203' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.394660000 AS Decimal(18, 9)), CAST(-70.513970000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(177.68231 AS Decimal(18, 5)), CAST(0.14600 AS Decimal(18, 5)), CAST(2.95800 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:45.160' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.394640000 AS Decimal(18, 9)), CAST(-70.514550000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(65.18127 AS Decimal(18, 5)), CAST(0.05423 AS Decimal(18, 5)), CAST(2.99500 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:48.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.393960000 AS Decimal(18, 9)), CAST(-70.515020000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(157.93385 AS Decimal(18, 5)), CAST(0.08778 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:50.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.392270000 AS Decimal(18, 9)), CAST(-70.514910000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(336.67034 AS Decimal(18, 5)), CAST(0.18760 AS Decimal(18, 5)), CAST(2.00600 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:52.163' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.391020000 AS Decimal(18, 9)), CAST(-70.514160000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(187.73031 AS Decimal(18, 5)), CAST(0.15618 AS Decimal(18, 5)), CAST(2.99500 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:55.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.390610000 AS Decimal(18, 9)), CAST(-70.513310000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(162.83444 AS Decimal(18, 5)), CAST(0.09028 AS Decimal(18, 5)), CAST(1.99600 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:57.153' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.390110000 AS Decimal(18, 9)), CAST(-70.511800000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(271.50721 AS Decimal(18, 5)), CAST(0.15091 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:06:59.153' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.390030000 AS Decimal(18, 9)), CAST(-70.509290000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(64.62938 AS Decimal(18, 5)), CAST(0.23340 AS Decimal(18, 5)), CAST(13.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:07:12.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.390170000 AS Decimal(18, 9)), CAST(-70.508740000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(23.95121 AS Decimal(18, 5)), CAST(0.05334 AS Decimal(18, 5)), CAST(8.01800 AS Decimal(18, 5)), CAST(N'2015-11-06 06:07:20.173' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.388480000 AS Decimal(18, 9)), CAST(-70.507110000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(290.31632 AS Decimal(18, 5)), CAST(0.24080 AS Decimal(18, 5)), CAST(2.98600 AS Decimal(18, 5)), CAST(N'2015-11-06 06:07:23.160' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.387390000 AS Decimal(18, 9)), CAST(-70.505420000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(238.31333 AS Decimal(18, 5)), CAST(0.19846 AS Decimal(18, 5)), CAST(2.99800 AS Decimal(18, 5)), CAST(N'2015-11-06 06:07:26.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.385800000 AS Decimal(18, 9)), CAST(-70.504280000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(370.15171 AS Decimal(18, 5)), CAST(0.20554 AS Decimal(18, 5)), CAST(1.99900 AS Decimal(18, 5)), CAST(N'2015-11-06 06:07:28.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.384870000 AS Decimal(18, 9)), CAST(-70.502650000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(39.10722 AS Decimal(18, 5)), CAST(0.18354 AS Decimal(18, 5)), CAST(16.89600 AS Decimal(18, 5)), CAST(N'2015-11-06 06:07:45.053' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.384680000 AS Decimal(18, 9)), CAST(-70.505690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(482.35135 AS Decimal(18, 5)), CAST(0.28271 AS Decimal(18, 5)), CAST(2.11000 AS Decimal(18, 5)), CAST(N'2015-11-06 06:07:47.163' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.384010000 AS Decimal(18, 9)), CAST(-70.505980000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(94.80120 AS Decimal(18, 5)), CAST(0.07887 AS Decimal(18, 5)), CAST(2.99500 AS Decimal(18, 5)), CAST(N'2015-11-06 06:07:50.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.383470000 AS Decimal(18, 9)), CAST(-70.506390000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(128.18443 AS Decimal(18, 5)), CAST(0.07125 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:07:52.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.382790000 AS Decimal(18, 9)), CAST(-70.506650000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(114.35507 AS Decimal(18, 5)), CAST(0.07875 AS Decimal(18, 5)), CAST(2.47900 AS Decimal(18, 5)), CAST(N'2015-11-06 06:07:54.637' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.382180000 AS Decimal(18, 9)), CAST(-70.506390000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(103.50787 AS Decimal(18, 5)), CAST(0.07243 AS Decimal(18, 5)), CAST(2.51900 AS Decimal(18, 5)), CAST(N'2015-11-06 06:07:57.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.382180000 AS Decimal(18, 9)), CAST(-70.506290000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(9.64352 AS Decimal(18, 5)), CAST(0.00931 AS Decimal(18, 5)), CAST(3.47400 AS Decimal(18, 5)), CAST(N'2015-11-06 06:08:00.630' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.382180000 AS Decimal(18, 9)), CAST(-70.506140000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(19.86292 AS Decimal(18, 5)), CAST(0.01396 AS Decimal(18, 5)), CAST(2.53100 AS Decimal(18, 5)), CAST(N'2015-11-06 06:08:03.160' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.382390000 AS Decimal(18, 9)), CAST(-70.503970000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(244.12924 AS Decimal(18, 5)), CAST(0.20337 AS Decimal(18, 5)), CAST(2.99900 AS Decimal(18, 5)), CAST(N'2015-11-06 06:08:06.160' AS DateTime))
GO
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.382290000 AS Decimal(18, 9)), CAST(-70.502250000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(164.75900 AS Decimal(18, 5)), CAST(0.15991 AS Decimal(18, 5)), CAST(3.49400 AS Decimal(18, 5)), CAST(N'2015-11-06 06:08:09.653' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.381720000 AS Decimal(18, 9)), CAST(-70.501300000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(156.01009 AS Decimal(18, 5)), CAST(0.10847 AS Decimal(18, 5)), CAST(2.50300 AS Decimal(18, 5)), CAST(N'2015-11-06 06:08:12.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.381200000 AS Decimal(18, 9)), CAST(-70.500490000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(127.45974 AS Decimal(18, 5)), CAST(0.09521 AS Decimal(18, 5)), CAST(2.68900 AS Decimal(18, 5)), CAST(N'2015-11-06 06:08:14.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (21, CAST(-33.380000000 AS Decimal(18, 9)), CAST(-70.499930000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(257.45144 AS Decimal(18, 5)), CAST(0.14303 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 06:08:16.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.381160000 AS Decimal(18, 9)), CAST(-70.512070000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 13:50:39.317' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.381440000 AS Decimal(18, 9)), CAST(-70.513400000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(229.33442 AS Decimal(18, 5)), CAST(0.12741 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 13:50:41.317' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.381750000 AS Decimal(18, 9)), CAST(-70.513680000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(76.85935 AS Decimal(18, 5)), CAST(0.04298 AS Decimal(18, 5)), CAST(2.01300 AS Decimal(18, 5)), CAST(N'2015-11-06 13:50:43.330' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.381990000 AS Decimal(18, 9)), CAST(-70.513890000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(58.98604 AS Decimal(18, 5)), CAST(0.03280 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-06 13:50:45.333' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.381250000 AS Decimal(18, 9)), CAST(-70.513980000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(149.28994 AS Decimal(18, 5)), CAST(0.08319 AS Decimal(18, 5)), CAST(2.00600 AS Decimal(18, 5)), CAST(N'2015-11-06 13:50:47.340' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.380450000 AS Decimal(18, 9)), CAST(-70.514360000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(171.97587 AS Decimal(18, 5)), CAST(0.09554 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 13:50:49.340' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.380140000 AS Decimal(18, 9)), CAST(-70.514630000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(77.25893 AS Decimal(18, 5)), CAST(0.04299 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-06 13:50:51.343' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.379560000 AS Decimal(18, 9)), CAST(-70.514380000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(122.76437 AS Decimal(18, 5)), CAST(0.06837 AS Decimal(18, 5)), CAST(2.00500 AS Decimal(18, 5)), CAST(N'2015-11-06 13:50:53.347' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.379120000 AS Decimal(18, 9)), CAST(-70.513800000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(130.94883 AS Decimal(18, 5)), CAST(0.07275 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 13:50:55.347' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.378270000 AS Decimal(18, 9)), CAST(-70.514180000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(180.44657 AS Decimal(18, 5)), CAST(0.10040 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-06 13:50:57.350' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.377780000 AS Decimal(18, 9)), CAST(-70.514680000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(130.20159 AS Decimal(18, 5)), CAST(0.07237 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 13:50:59.350' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.377020000 AS Decimal(18, 9)), CAST(-70.514910000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(157.42479 AS Decimal(18, 5)), CAST(0.08746 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 13:51:01.350' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.376350000 AS Decimal(18, 9)), CAST(-70.515320000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(149.17373 AS Decimal(18, 5)), CAST(0.08292 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-06 13:51:03.353' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.375550000 AS Decimal(18, 9)), CAST(-70.516480000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(251.96139 AS Decimal(18, 5)), CAST(0.13998 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 13:51:05.353' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (22, CAST(-33.375180000 AS Decimal(18, 9)), CAST(-70.517130000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(131.54127 AS Decimal(18, 5)), CAST(0.07308 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-06 13:51:07.353' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (10, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.550300000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 00:46:55.067' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (10, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.549540000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(127.06642 AS Decimal(18, 5)), CAST(0.07063 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 00:46:57.067' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (10, CAST(-33.407450000 AS Decimal(18, 9)), CAST(-70.549680000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(165.28400 AS Decimal(18, 5)), CAST(0.09192 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-05 00:46:59.067' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.552450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-04 23:04:12.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.408310000 AS Decimal(18, 9)), CAST(-70.551620000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(138.15382 AS Decimal(18, 5)), CAST(0.07679 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-04 23:04:14.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.408530000 AS Decimal(18, 9)), CAST(-70.550800000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(144.44005 AS Decimal(18, 5)), CAST(0.08028 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-04 23:04:35.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.550300000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(93.05789 AS Decimal(18, 5)), CAST(0.05175 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:04:37.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.549540000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(127.32093 AS Decimal(18, 5)), CAST(0.07063 AS Decimal(18, 5)), CAST(1.99700 AS Decimal(18, 5)), CAST(N'2015-11-04 23:04:39.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.407450000 AS Decimal(18, 9)), CAST(-70.549680000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(164.95443 AS Decimal(18, 5)), CAST(0.09192 AS Decimal(18, 5)), CAST(2.00600 AS Decimal(18, 5)), CAST(N'2015-11-04 23:04:41.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.406820000 AS Decimal(18, 9)), CAST(-70.548560000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(90.25037 AS Decimal(18, 5)), CAST(0.12530 AS Decimal(18, 5)), CAST(4.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:04:46.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.406890000 AS Decimal(18, 9)), CAST(-70.548450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(24.37067 AS Decimal(18, 5)), CAST(0.01351 AS Decimal(18, 5)), CAST(1.99600 AS Decimal(18, 5)), CAST(N'2015-11-04 23:04:48.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.406980000 AS Decimal(18, 9)), CAST(-70.548350000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(24.09946 AS Decimal(18, 5)), CAST(0.01340 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-04 23:04:50.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.407460000 AS Decimal(18, 9)), CAST(-70.548000000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(56.34314 AS Decimal(18, 5)), CAST(0.06260 AS Decimal(18, 5)), CAST(4.00000 AS Decimal(18, 5)), CAST(N'2015-11-04 23:04:54.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.407980000 AS Decimal(18, 9)), CAST(-70.547870000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(52.73948 AS Decimal(18, 5)), CAST(0.05860 AS Decimal(18, 5)), CAST(4.00000 AS Decimal(18, 5)), CAST(N'2015-11-04 23:04:58.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.408050000 AS Decimal(18, 9)), CAST(-70.547310000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(93.63949 AS Decimal(18, 5)), CAST(0.05207 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:05:00.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.407920000 AS Decimal(18, 9)), CAST(-70.546690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(108.19629 AS Decimal(18, 5)), CAST(0.06023 AS Decimal(18, 5)), CAST(2.00400 AS Decimal(18, 5)), CAST(N'2015-11-04 23:05:02.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.407920000 AS Decimal(18, 9)), CAST(-70.545880000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(90.02436 AS Decimal(18, 5)), CAST(0.07497 AS Decimal(18, 5)), CAST(2.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:05:05.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.407650000 AS Decimal(18, 9)), CAST(-70.545030000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(101.42420 AS Decimal(18, 5)), CAST(0.08444 AS Decimal(18, 5)), CAST(2.99700 AS Decimal(18, 5)), CAST(N'2015-11-04 23:05:08.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.406810000 AS Decimal(18, 9)), CAST(-70.544400000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(197.43033 AS Decimal(18, 5)), CAST(0.10968 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-04 23:05:10.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.406710000 AS Decimal(18, 9)), CAST(-70.544290000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(26.68575 AS Decimal(18, 5)), CAST(0.01483 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-04 23:05:12.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.406440000 AS Decimal(18, 9)), CAST(-70.543600000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(127.82841 AS Decimal(18, 5)), CAST(0.07109 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:05:14.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (6, CAST(-33.406330000 AS Decimal(18, 9)), CAST(-70.543380000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(43.17559 AS Decimal(18, 5)), CAST(0.02400 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-04 23:05:16.000' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.408140000 AS Decimal(18, 9)), CAST(-70.554220000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-04 23:43:03.833' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.408340000 AS Decimal(18, 9)), CAST(-70.553080000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(96.90487 AS Decimal(18, 5)), CAST(0.10778 AS Decimal(18, 5)), CAST(4.00400 AS Decimal(18, 5)), CAST(N'2015-11-04 23:43:07.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.552450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(70.43441 AS Decimal(18, 5)), CAST(0.05873 AS Decimal(18, 5)), CAST(3.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:43:10.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.408310000 AS Decimal(18, 9)), CAST(-70.551620000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(92.21007 AS Decimal(18, 5)), CAST(0.07679 AS Decimal(18, 5)), CAST(2.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:43:13.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.408530000 AS Decimal(18, 9)), CAST(-70.550800000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(96.37364 AS Decimal(18, 5)), CAST(0.08028 AS Decimal(18, 5)), CAST(2.99900 AS Decimal(18, 5)), CAST(N'2015-11-04 23:43:33.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.550300000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(62.16279 AS Decimal(18, 5)), CAST(0.05175 AS Decimal(18, 5)), CAST(2.99700 AS Decimal(18, 5)), CAST(N'2015-11-04 23:43:36.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.407450000 AS Decimal(18, 9)), CAST(-70.549680000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(101.67307 AS Decimal(18, 5)), CAST(0.11311 AS Decimal(18, 5)), CAST(4.00500 AS Decimal(18, 5)), CAST(N'2015-11-04 23:43:40.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.406920000 AS Decimal(18, 9)), CAST(-70.549180000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(90.67172 AS Decimal(18, 5)), CAST(0.07556 AS Decimal(18, 5)), CAST(3.00000 AS Decimal(18, 5)), CAST(N'2015-11-04 23:43:43.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.406820000 AS Decimal(18, 9)), CAST(-70.548560000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(70.02530 AS Decimal(18, 5)), CAST(0.05832 AS Decimal(18, 5)), CAST(2.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:43:46.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.406890000 AS Decimal(18, 9)), CAST(-70.548450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(16.20381 AS Decimal(18, 5)), CAST(0.01351 AS Decimal(18, 5)), CAST(3.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:43:49.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.406980000 AS Decimal(18, 9)), CAST(-70.548350000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(16.09043 AS Decimal(18, 5)), CAST(0.01340 AS Decimal(18, 5)), CAST(2.99700 AS Decimal(18, 5)), CAST(N'2015-11-04 23:43:52.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.407460000 AS Decimal(18, 9)), CAST(-70.548000000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(56.35723 AS Decimal(18, 5)), CAST(0.06260 AS Decimal(18, 5)), CAST(3.99900 AS Decimal(18, 5)), CAST(N'2015-11-04 23:43:56.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.407740000 AS Decimal(18, 9)), CAST(-70.547990000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(55.78520 AS Decimal(18, 5)), CAST(0.03098 AS Decimal(18, 5)), CAST(1.99900 AS Decimal(18, 5)), CAST(N'2015-11-04 23:43:58.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.407980000 AS Decimal(18, 9)), CAST(-70.547870000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(51.42926 AS Decimal(18, 5)), CAST(0.02859 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:00.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.407920000 AS Decimal(18, 9)), CAST(-70.546690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(98.81420 AS Decimal(18, 5)), CAST(0.10990 AS Decimal(18, 5)), CAST(4.00400 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:04.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.407920000 AS Decimal(18, 9)), CAST(-70.545880000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(90.02436 AS Decimal(18, 5)), CAST(0.07497 AS Decimal(18, 5)), CAST(2.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:07.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.407650000 AS Decimal(18, 9)), CAST(-70.545030000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(152.13629 AS Decimal(18, 5)), CAST(0.08444 AS Decimal(18, 5)), CAST(1.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:09.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.406810000 AS Decimal(18, 9)), CAST(-70.544400000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(197.13463 AS Decimal(18, 5)), CAST(0.10968 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:11.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.406710000 AS Decimal(18, 9)), CAST(-70.544290000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(26.65909 AS Decimal(18, 5)), CAST(0.01483 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:13.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.406440000 AS Decimal(18, 9)), CAST(-70.543600000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(85.41805 AS Decimal(18, 5)), CAST(0.07109 AS Decimal(18, 5)), CAST(2.99600 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:16.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.406330000 AS Decimal(18, 9)), CAST(-70.543380000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(43.15402 AS Decimal(18, 5)), CAST(0.02400 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:18.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.405540000 AS Decimal(18, 9)), CAST(-70.540720000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(235.66817 AS Decimal(18, 5)), CAST(0.26185 AS Decimal(18, 5)), CAST(4.00000 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:22.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.405290000 AS Decimal(18, 9)), CAST(-70.539180000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(261.56542 AS Decimal(18, 5)), CAST(0.14546 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:24.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.404630000 AS Decimal(18, 9)), CAST(-70.537900000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(167.89704 AS Decimal(18, 5)), CAST(0.13996 AS Decimal(18, 5)), CAST(3.00100 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:27.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.403240000 AS Decimal(18, 9)), CAST(-70.536960000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(213.86829 AS Decimal(18, 5)), CAST(0.17793 AS Decimal(18, 5)), CAST(2.99500 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:30.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.403190000 AS Decimal(18, 9)), CAST(-70.536900000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(12.61286 AS Decimal(18, 5)), CAST(0.00701 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:32.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.403100000 AS Decimal(18, 9)), CAST(-70.536810000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(23.19526 AS Decimal(18, 5)), CAST(0.01291 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:34.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.401830000 AS Decimal(18, 9)), CAST(-70.536020000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(192.13234 AS Decimal(18, 5)), CAST(0.16011 AS Decimal(18, 5)), CAST(3.00000 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:37.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.399940000 AS Decimal(18, 9)), CAST(-70.535050000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(410.48823 AS Decimal(18, 5)), CAST(0.22771 AS Decimal(18, 5)), CAST(1.99700 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:39.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.398920000 AS Decimal(18, 9)), CAST(-70.533810000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(290.81723 AS Decimal(18, 5)), CAST(0.16157 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:41.837' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.398610000 AS Decimal(18, 9)), CAST(-70.532550000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(219.67862 AS Decimal(18, 5)), CAST(0.12229 AS Decimal(18, 5)), CAST(2.00400 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:43.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.398610000 AS Decimal(18, 9)), CAST(-70.531920000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(106.34126 AS Decimal(18, 5)), CAST(0.05902 AS Decimal(18, 5)), CAST(1.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:45.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.397510000 AS Decimal(18, 9)), CAST(-70.531390000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(235.35267 AS Decimal(18, 5)), CAST(0.13069 AS Decimal(18, 5)), CAST(1.99900 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:47.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.396160000 AS Decimal(18, 9)), CAST(-70.531360000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(269.70657 AS Decimal(18, 5)), CAST(0.15014 AS Decimal(18, 5)), CAST(2.00400 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:49.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.394940000 AS Decimal(18, 9)), CAST(-70.531350000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(163.42530 AS Decimal(18, 5)), CAST(0.13610 AS Decimal(18, 5)), CAST(2.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:52.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.393620000 AS Decimal(18, 9)), CAST(-70.531030000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(269.20079 AS Decimal(18, 5)), CAST(0.14941 AS Decimal(18, 5)), CAST(1.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:54.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.392530000 AS Decimal(18, 9)), CAST(-70.530210000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(257.62441 AS Decimal(18, 5)), CAST(0.14341 AS Decimal(18, 5)), CAST(2.00400 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:56.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.392460000 AS Decimal(18, 9)), CAST(-70.530040000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(20.23151 AS Decimal(18, 5)), CAST(0.01685 AS Decimal(18, 5)), CAST(2.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:44:59.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.392440000 AS Decimal(18, 9)), CAST(-70.529910000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(23.07794 AS Decimal(18, 5)), CAST(0.01283 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:01.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.392150000 AS Decimal(18, 9)), CAST(-70.529120000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(71.78145 AS Decimal(18, 5)), CAST(0.07978 AS Decimal(18, 5)), CAST(4.00100 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:05.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.392640000 AS Decimal(18, 9)), CAST(-70.527820000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(159.58487 AS Decimal(18, 5)), CAST(0.13281 AS Decimal(18, 5)), CAST(2.99600 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:08.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.394520000 AS Decimal(18, 9)), CAST(-70.528290000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(384.66152 AS Decimal(18, 5)), CAST(0.21391 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:10.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.394610000 AS Decimal(18, 9)), CAST(-70.528290000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(18.30340 AS Decimal(18, 5)), CAST(0.01016 AS Decimal(18, 5)), CAST(1.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:12.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.396130000 AS Decimal(18, 9)), CAST(-70.528490000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(305.48868 AS Decimal(18, 5)), CAST(0.16989 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:14.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.397430000 AS Decimal(18, 9)), CAST(-70.528490000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(260.83879 AS Decimal(18, 5)), CAST(0.14477 AS Decimal(18, 5)), CAST(1.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:16.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.398300000 AS Decimal(18, 9)), CAST(-70.528480000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(174.10226 AS Decimal(18, 5)), CAST(0.09672 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:18.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.398950000 AS Decimal(18, 9)), CAST(-70.528690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(66.70086 AS Decimal(18, 5)), CAST(0.07417 AS Decimal(18, 5)), CAST(4.00300 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:22.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.400250000 AS Decimal(18, 9)), CAST(-70.528890000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(263.32979 AS Decimal(18, 5)), CAST(0.14622 AS Decimal(18, 5)), CAST(1.99900 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:24.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.401680000 AS Decimal(18, 9)), CAST(-70.528880000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(285.48894 AS Decimal(18, 5)), CAST(0.15860 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:26.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.402580000 AS Decimal(18, 9)), CAST(-70.527270000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(323.59117 AS Decimal(18, 5)), CAST(0.17995 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:28.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.402910000 AS Decimal(18, 9)), CAST(-70.520200000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(473.77159 AS Decimal(18, 5)), CAST(0.65775 AS Decimal(18, 5)), CAST(4.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:33.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.403330000 AS Decimal(18, 9)), CAST(-70.516980000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(543.29598 AS Decimal(18, 5)), CAST(0.30198 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:35.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.401940000 AS Decimal(18, 9)), CAST(-70.516350000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(298.76231 AS Decimal(18, 5)), CAST(0.16581 AS Decimal(18, 5)), CAST(1.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:37.840' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.399560000 AS Decimal(18, 9)), CAST(-70.516140000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(476.71895 AS Decimal(18, 5)), CAST(0.26551 AS Decimal(18, 5)), CAST(2.00500 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:39.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.397540000 AS Decimal(18, 9)), CAST(-70.515260000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(286.60910 AS Decimal(18, 5)), CAST(0.23852 AS Decimal(18, 5)), CAST(2.99600 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:42.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.395870000 AS Decimal(18, 9)), CAST(-70.514950000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(169.14021 AS Decimal(18, 5)), CAST(0.18803 AS Decimal(18, 5)), CAST(4.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:46.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.395720000 AS Decimal(18, 9)), CAST(-70.514900000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(31.84311 AS Decimal(18, 5)), CAST(0.01767 AS Decimal(18, 5)), CAST(1.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:48.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.394640000 AS Decimal(18, 9)), CAST(-70.514550000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(111.55361 AS Decimal(18, 5)), CAST(0.12404 AS Decimal(18, 5)), CAST(4.00300 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:52.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.393960000 AS Decimal(18, 9)), CAST(-70.515020000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(158.09186 AS Decimal(18, 5)), CAST(0.08778 AS Decimal(18, 5)), CAST(1.99900 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:54.843' AS DateTime))
GO
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.392270000 AS Decimal(18, 9)), CAST(-70.514910000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(338.01837 AS Decimal(18, 5)), CAST(0.18760 AS Decimal(18, 5)), CAST(1.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:45:56.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.390610000 AS Decimal(18, 9)), CAST(-70.513310000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(212.92761 AS Decimal(18, 5)), CAST(0.23670 AS Decimal(18, 5)), CAST(4.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:00.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.390110000 AS Decimal(18, 9)), CAST(-70.511800000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(271.64296 AS Decimal(18, 5)), CAST(0.15091 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:02.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.389790000 AS Decimal(18, 9)), CAST(-70.510760000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(185.09509 AS Decimal(18, 5)), CAST(0.10309 AS Decimal(18, 5)), CAST(2.00500 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:04.850' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.390030000 AS Decimal(18, 9)), CAST(-70.509290000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(167.01432 AS Decimal(18, 5)), CAST(0.13899 AS Decimal(18, 5)), CAST(2.99600 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:07.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.390170000 AS Decimal(18, 9)), CAST(-70.508740000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(96.11653 AS Decimal(18, 5)), CAST(0.05334 AS Decimal(18, 5)), CAST(1.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:09.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.388480000 AS Decimal(18, 9)), CAST(-70.507110000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(432.79308 AS Decimal(18, 5)), CAST(0.24080 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:11.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.387390000 AS Decimal(18, 9)), CAST(-70.505420000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(357.58928 AS Decimal(18, 5)), CAST(0.19846 AS Decimal(18, 5)), CAST(1.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:13.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.385800000 AS Decimal(18, 9)), CAST(-70.504280000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(369.59703 AS Decimal(18, 5)), CAST(0.20554 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:15.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.384870000 AS Decimal(18, 9)), CAST(-70.502650000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(330.70854 AS Decimal(18, 5)), CAST(0.18354 AS Decimal(18, 5)), CAST(1.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:17.843' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.384680000 AS Decimal(18, 9)), CAST(-70.505690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(508.62636 AS Decimal(18, 5)), CAST(0.28271 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:19.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.384010000 AS Decimal(18, 9)), CAST(-70.505980000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(141.75217 AS Decimal(18, 5)), CAST(0.07887 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:21.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.383470000 AS Decimal(18, 9)), CAST(-70.506390000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(85.58460 AS Decimal(18, 5)), CAST(0.07125 AS Decimal(18, 5)), CAST(2.99700 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:24.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.382180000 AS Decimal(18, 9)), CAST(-70.506390000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(128.98141 AS Decimal(18, 5)), CAST(0.14338 AS Decimal(18, 5)), CAST(4.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:28.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.382180000 AS Decimal(18, 9)), CAST(-70.506290000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(16.74242 AS Decimal(18, 5)), CAST(0.00931 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:30.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.382180000 AS Decimal(18, 9)), CAST(-70.506140000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(16.76887 AS Decimal(18, 5)), CAST(0.01396 AS Decimal(18, 5)), CAST(2.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:33.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.382390000 AS Decimal(18, 9)), CAST(-70.503970000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(365.70608 AS Decimal(18, 5)), CAST(0.20337 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:35.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.382290000 AS Decimal(18, 9)), CAST(-70.502250000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(288.12209 AS Decimal(18, 5)), CAST(0.15991 AS Decimal(18, 5)), CAST(1.99800 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:37.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.381720000 AS Decimal(18, 9)), CAST(-70.501300000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(195.34430 AS Decimal(18, 5)), CAST(0.10847 AS Decimal(18, 5)), CAST(1.99900 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:39.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.381200000 AS Decimal(18, 9)), CAST(-70.500490000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(171.11296 AS Decimal(18, 5)), CAST(0.09521 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:41.847' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.380000000 AS Decimal(18, 9)), CAST(-70.499930000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(257.32278 AS Decimal(18, 5)), CAST(0.14303 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:43.850' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (8, CAST(-33.379740000 AS Decimal(18, 9)), CAST(-70.499920000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(51.49738 AS Decimal(18, 5)), CAST(0.02868 AS Decimal(18, 5)), CAST(2.00500 AS Decimal(18, 5)), CAST(N'2015-11-04 23:46:45.853' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (11, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.553690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:21:20.307' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (11, CAST(-33.408340000 AS Decimal(18, 9)), CAST(-70.553080000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(102.29886 AS Decimal(18, 5)), CAST(0.05683 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:21:22.307' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (11, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.552450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(74.16489 AS Decimal(18, 5)), CAST(0.05873 AS Decimal(18, 5)), CAST(2.85100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:21:25.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (11, CAST(-33.408310000 AS Decimal(18, 9)), CAST(-70.551620000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(138.29204 AS Decimal(18, 5)), CAST(0.07679 AS Decimal(18, 5)), CAST(1.99900 AS Decimal(18, 5)), CAST(N'2015-11-05 01:21:27.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (12, CAST(-33.408060000 AS Decimal(18, 9)), CAST(-70.555090000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:29.513' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (12, CAST(-33.408140000 AS Decimal(18, 9)), CAST(-70.554220000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(145.47864 AS Decimal(18, 5)), CAST(0.08086 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:31.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (12, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.553690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(92.29427 AS Decimal(18, 5)), CAST(0.05127 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:33.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (12, CAST(-33.408340000 AS Decimal(18, 9)), CAST(-70.553080000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(102.29886 AS Decimal(18, 5)), CAST(0.05683 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:35.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (12, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.552450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(105.66921 AS Decimal(18, 5)), CAST(0.05873 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:37.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (12, CAST(-33.408310000 AS Decimal(18, 9)), CAST(-70.551620000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(138.08481 AS Decimal(18, 5)), CAST(0.07679 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:39.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (13, CAST(-33.408060000 AS Decimal(18, 9)), CAST(-70.555090000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:29.513' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (13, CAST(-33.408140000 AS Decimal(18, 9)), CAST(-70.554220000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(145.47864 AS Decimal(18, 5)), CAST(0.08086 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:31.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (13, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.553690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(92.29427 AS Decimal(18, 5)), CAST(0.05127 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:33.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (13, CAST(-33.408340000 AS Decimal(18, 9)), CAST(-70.553080000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(102.29886 AS Decimal(18, 5)), CAST(0.05683 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:35.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (13, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.552450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(105.66921 AS Decimal(18, 5)), CAST(0.05873 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:37.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (13, CAST(-33.408310000 AS Decimal(18, 9)), CAST(-70.551620000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(138.08481 AS Decimal(18, 5)), CAST(0.07679 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:39.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (14, CAST(-33.408060000 AS Decimal(18, 9)), CAST(-70.555090000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:29.513' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (14, CAST(-33.408140000 AS Decimal(18, 9)), CAST(-70.554220000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(145.47864 AS Decimal(18, 5)), CAST(0.08086 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:31.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (14, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.553690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(92.29427 AS Decimal(18, 5)), CAST(0.05127 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:33.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (14, CAST(-33.408340000 AS Decimal(18, 9)), CAST(-70.553080000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(102.29886 AS Decimal(18, 5)), CAST(0.05683 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:35.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (14, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.552450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(105.66921 AS Decimal(18, 5)), CAST(0.05873 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:37.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (14, CAST(-33.408310000 AS Decimal(18, 9)), CAST(-70.551620000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(138.08481 AS Decimal(18, 5)), CAST(0.07679 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:39.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (15, CAST(-33.408060000 AS Decimal(18, 9)), CAST(-70.555090000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:29.513' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (15, CAST(-33.408140000 AS Decimal(18, 9)), CAST(-70.554220000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(145.47864 AS Decimal(18, 5)), CAST(0.08086 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:31.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (15, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.553690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(92.29427 AS Decimal(18, 5)), CAST(0.05127 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:33.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (15, CAST(-33.408340000 AS Decimal(18, 9)), CAST(-70.553080000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(102.29886 AS Decimal(18, 5)), CAST(0.05683 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:35.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (15, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.552450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(105.66921 AS Decimal(18, 5)), CAST(0.05873 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:37.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (15, CAST(-33.408310000 AS Decimal(18, 9)), CAST(-70.551620000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(138.08481 AS Decimal(18, 5)), CAST(0.07679 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:39.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (16, CAST(-33.408060000 AS Decimal(18, 9)), CAST(-70.555090000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:29.513' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (16, CAST(-33.408140000 AS Decimal(18, 9)), CAST(-70.554220000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(145.47864 AS Decimal(18, 5)), CAST(0.08086 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:31.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (16, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.553690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(92.29427 AS Decimal(18, 5)), CAST(0.05127 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:33.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (16, CAST(-33.408340000 AS Decimal(18, 9)), CAST(-70.553080000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(102.29886 AS Decimal(18, 5)), CAST(0.05683 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:35.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (16, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.552450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(105.66921 AS Decimal(18, 5)), CAST(0.05873 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:37.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (16, CAST(-33.408310000 AS Decimal(18, 9)), CAST(-70.551620000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(138.08481 AS Decimal(18, 5)), CAST(0.07679 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:39.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (17, CAST(-33.408060000 AS Decimal(18, 9)), CAST(-70.555090000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:29.513' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (17, CAST(-33.408140000 AS Decimal(18, 9)), CAST(-70.554220000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(145.47864 AS Decimal(18, 5)), CAST(0.08086 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:31.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (17, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.553690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(92.29427 AS Decimal(18, 5)), CAST(0.05127 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:33.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (17, CAST(-33.408340000 AS Decimal(18, 9)), CAST(-70.553080000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(102.29886 AS Decimal(18, 5)), CAST(0.05683 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:35.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (17, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.552450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(105.66921 AS Decimal(18, 5)), CAST(0.05873 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:37.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (17, CAST(-33.408310000 AS Decimal(18, 9)), CAST(-70.551620000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(138.08481 AS Decimal(18, 5)), CAST(0.07679 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-05 01:22:39.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (18, CAST(-33.408060000 AS Decimal(18, 9)), CAST(-70.555090000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 01:28:39.177' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (18, CAST(-33.408140000 AS Decimal(18, 9)), CAST(-70.554220000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(145.18841 AS Decimal(18, 5)), CAST(0.08086 AS Decimal(18, 5)), CAST(2.00500 AS Decimal(18, 5)), CAST(N'2015-11-05 01:28:41.180' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (18, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.553690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(61.55003 AS Decimal(18, 5)), CAST(0.05127 AS Decimal(18, 5)), CAST(2.99900 AS Decimal(18, 5)), CAST(N'2015-11-05 01:28:44.180' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (18, CAST(-33.408340000 AS Decimal(18, 9)), CAST(-70.553080000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(102.45254 AS Decimal(18, 5)), CAST(0.05683 AS Decimal(18, 5)), CAST(1.99700 AS Decimal(18, 5)), CAST(N'2015-11-05 01:28:46.177' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (18, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.552450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(105.56370 AS Decimal(18, 5)), CAST(0.05873 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-05 01:28:48.180' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (18, CAST(-33.408310000 AS Decimal(18, 9)), CAST(-70.551620000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(138.15382 AS Decimal(18, 5)), CAST(0.07679 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:28:50.180' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (18, CAST(-33.408530000 AS Decimal(18, 9)), CAST(-70.550800000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(144.44005 AS Decimal(18, 5)), CAST(0.08028 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 01:29:15.180' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (18, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.550300000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(93.05789 AS Decimal(18, 5)), CAST(0.05175 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-05 01:29:17.183' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.408060000 AS Decimal(18, 9)), CAST(-70.555090000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:12.510' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.408140000 AS Decimal(18, 9)), CAST(-70.554220000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(145.55138 AS Decimal(18, 5)), CAST(0.08086 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:14.510' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.553690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(92.24814 AS Decimal(18, 5)), CAST(0.05127 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:16.513' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.408340000 AS Decimal(18, 9)), CAST(-70.553080000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(102.29886 AS Decimal(18, 5)), CAST(0.05683 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:18.513' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.552450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(105.66921 AS Decimal(18, 5)), CAST(0.05873 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:20.513' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.408310000 AS Decimal(18, 9)), CAST(-70.551620000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(137.94700 AS Decimal(18, 5)), CAST(0.07679 AS Decimal(18, 5)), CAST(2.00400 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:22.517' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.408530000 AS Decimal(18, 9)), CAST(-70.550800000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(144.36790 AS Decimal(18, 5)), CAST(0.08028 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:40.547' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.408330000 AS Decimal(18, 9)), CAST(-70.550300000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(92.91865 AS Decimal(18, 5)), CAST(0.05175 AS Decimal(18, 5)), CAST(2.00500 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:42.553' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.408270000 AS Decimal(18, 9)), CAST(-70.549540000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(126.93954 AS Decimal(18, 5)), CAST(0.07063 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:44.557' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.407450000 AS Decimal(18, 9)), CAST(-70.549680000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(165.36661 AS Decimal(18, 5)), CAST(0.09192 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:46.557' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.406920000 AS Decimal(18, 9)), CAST(-70.549180000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(135.73611 AS Decimal(18, 5)), CAST(0.07556 AS Decimal(18, 5)), CAST(2.00400 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:48.560' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.406820000 AS Decimal(18, 9)), CAST(-70.548560000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(104.70617 AS Decimal(18, 5)), CAST(0.05832 AS Decimal(18, 5)), CAST(2.00500 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:50.567' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.406890000 AS Decimal(18, 9)), CAST(-70.548450000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(24.29763 AS Decimal(18, 5)), CAST(0.01351 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:52.567' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.406980000 AS Decimal(18, 9)), CAST(-70.548350000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(24.08742 AS Decimal(18, 5)), CAST(0.01340 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:54.570' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.407460000 AS Decimal(18, 9)), CAST(-70.548000000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(56.25875 AS Decimal(18, 5)), CAST(0.06260 AS Decimal(18, 5)), CAST(4.00600 AS Decimal(18, 5)), CAST(N'2015-11-05 19:36:58.577' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.407740000 AS Decimal(18, 9)), CAST(-70.547990000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(55.61826 AS Decimal(18, 5)), CAST(0.03098 AS Decimal(18, 5)), CAST(2.00500 AS Decimal(18, 5)), CAST(N'2015-11-05 19:37:00.580' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.407980000 AS Decimal(18, 9)), CAST(-70.547870000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(51.37791 AS Decimal(18, 5)), CAST(0.02859 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-05 19:37:02.583' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.408050000 AS Decimal(18, 9)), CAST(-70.547310000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(93.59274 AS Decimal(18, 5)), CAST(0.05207 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-05 19:37:04.587' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.407920000 AS Decimal(18, 9)), CAST(-70.546690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(108.25031 AS Decimal(18, 5)), CAST(0.06023 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-05 19:37:06.590' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.407920000 AS Decimal(18, 9)), CAST(-70.545880000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(134.87908 AS Decimal(18, 5)), CAST(0.07497 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 19:37:08.590' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.407650000 AS Decimal(18, 9)), CAST(-70.545030000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(151.90820 AS Decimal(18, 5)), CAST(0.08444 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 19:37:10.590' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.406810000 AS Decimal(18, 9)), CAST(-70.544400000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(197.13463 AS Decimal(18, 5)), CAST(0.10968 AS Decimal(18, 5)), CAST(2.00300 AS Decimal(18, 5)), CAST(N'2015-11-05 19:37:12.593' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.406710000 AS Decimal(18, 9)), CAST(-70.544290000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(26.60593 AS Decimal(18, 5)), CAST(0.01483 AS Decimal(18, 5)), CAST(2.00600 AS Decimal(18, 5)), CAST(N'2015-11-05 19:37:14.600' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.406440000 AS Decimal(18, 9)), CAST(-70.543600000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(127.95624 AS Decimal(18, 5)), CAST(0.07109 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 19:37:16.600' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.406330000 AS Decimal(18, 9)), CAST(-70.543380000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(43.17559 AS Decimal(18, 5)), CAST(0.02400 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 19:37:18.600' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.405780000 AS Decimal(18, 9)), CAST(-70.541940000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(263.84591 AS Decimal(18, 5)), CAST(0.14658 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 19:37:20.600' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.405540000 AS Decimal(18, 9)), CAST(-70.540720000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(209.90702 AS Decimal(18, 5)), CAST(0.11662 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 19:37:22.600' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (20, CAST(-33.405290000 AS Decimal(18, 9)), CAST(-70.539180000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(261.69613 AS Decimal(18, 5)), CAST(0.14546 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 19:37:24.603' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.397430000 AS Decimal(18, 9)), CAST(-70.528490000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(0.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:02.043' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.398300000 AS Decimal(18, 9)), CAST(-70.528480000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(174.01525 AS Decimal(18, 5)), CAST(0.09672 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:04.043' AS DateTime))
GO
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.398440000 AS Decimal(18, 9)), CAST(-70.528480000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(26.72373 AS Decimal(18, 5)), CAST(0.01485 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:06.043' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.398950000 AS Decimal(18, 9)), CAST(-70.528690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(101.41817 AS Decimal(18, 5)), CAST(0.05998 AS Decimal(18, 5)), CAST(2.12900 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:08.173' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.400250000 AS Decimal(18, 9)), CAST(-70.528890000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(266.12550 AS Decimal(18, 5)), CAST(0.14622 AS Decimal(18, 5)), CAST(1.97800 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:10.150' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.401680000 AS Decimal(18, 9)), CAST(-70.528880000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(284.91911 AS Decimal(18, 5)), CAST(0.15860 AS Decimal(18, 5)), CAST(2.00400 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:12.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.402580000 AS Decimal(18, 9)), CAST(-70.527270000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(323.91476 AS Decimal(18, 5)), CAST(0.17995 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:14.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.402750000 AS Decimal(18, 9)), CAST(-70.524560000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(454.24341 AS Decimal(18, 5)), CAST(0.25248 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:16.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.402910000 AS Decimal(18, 9)), CAST(-70.520200000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(729.23336 AS Decimal(18, 5)), CAST(0.40533 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:18.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.403330000 AS Decimal(18, 9)), CAST(-70.516980000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(543.56763 AS Decimal(18, 5)), CAST(0.30198 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:20.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.401940000 AS Decimal(18, 9)), CAST(-70.516350000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(298.31439 AS Decimal(18, 5)), CAST(0.16581 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:22.157' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.399560000 AS Decimal(18, 9)), CAST(-70.516140000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(476.71895 AS Decimal(18, 5)), CAST(0.26551 AS Decimal(18, 5)), CAST(2.00500 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:24.163' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.397540000 AS Decimal(18, 9)), CAST(-70.515260000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(429.34043 AS Decimal(18, 5)), CAST(0.23852 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:26.163' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.395870000 AS Decimal(18, 9)), CAST(-70.514950000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(169.09795 AS Decimal(18, 5)), CAST(0.18803 AS Decimal(18, 5)), CAST(4.00300 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:30.167' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.395720000 AS Decimal(18, 9)), CAST(-70.514900000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(31.79537 AS Decimal(18, 5)), CAST(0.01767 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:32.167' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.394660000 AS Decimal(18, 9)), CAST(-70.513970000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(262.52961 AS Decimal(18, 5)), CAST(0.14600 AS Decimal(18, 5)), CAST(2.00200 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:34.170' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.394640000 AS Decimal(18, 9)), CAST(-70.514550000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(97.60895 AS Decimal(18, 5)), CAST(0.05423 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:36.170' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.393960000 AS Decimal(18, 9)), CAST(-70.515020000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(157.93385 AS Decimal(18, 5)), CAST(0.08778 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:38.170' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.392270000 AS Decimal(18, 9)), CAST(-70.514910000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(337.51159 AS Decimal(18, 5)), CAST(0.18760 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:40.170' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.391020000 AS Decimal(18, 9)), CAST(-70.514160000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(281.12614 AS Decimal(18, 5)), CAST(0.15618 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:42.170' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.390610000 AS Decimal(18, 9)), CAST(-70.513310000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(162.42756 AS Decimal(18, 5)), CAST(0.09028 AS Decimal(18, 5)), CAST(2.00100 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:44.173' AS DateTime))
INSERT [dbo].[TB_MOT_Coordenada] ([COOR_RUTA_Codigo], [COOR_Latitud], [COOR_Longitud], [COOR_Altitud], [COOR_Velocidad], [COOR_Distancia], [COOR_Duracion], [COOR_Fecha]) VALUES (19, CAST(-33.390110000 AS Decimal(18, 9)), CAST(-70.511800000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), CAST(271.64296 AS Decimal(18, 5)), CAST(0.15091 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), CAST(N'2015-11-05 03:12:46.173' AS DateTime))
SET IDENTITY_INSERT [dbo].[TB_MOT_Notificacion] ON 

INSERT [dbo].[TB_MOT_Notificacion] ([NOTI_Codigo], [NOTI_USUA_Codigo], [NOTI_TINO_Identificador], [NOTI_Texto], [NOTI_Fecha], [NOTI_Leida], [NOTI_Token], [NOTI_Imagen], [NOTI_Contexto]) VALUES (1, 36, N'INFO', N'Se ha compartido tu ruta', CAST(N'2015-11-05 14:41:58.263' AS DateTime), 1, N'b467f07e-3fc2-4ffe-ae3a-4fd21e49fb55', N'cd13a4ba-e24a-481b-81a9-0a1c2c9716b9', N'88349ca2-5e62-4a04-b844-e2193301b1cc')
INSERT [dbo].[TB_MOT_Notificacion] ([NOTI_Codigo], [NOTI_USUA_Codigo], [NOTI_TINO_Identificador], [NOTI_Texto], [NOTI_Fecha], [NOTI_Leida], [NOTI_Token], [NOTI_Imagen], [NOTI_Contexto]) VALUES (3, 36, N'RUCO', N'Jonathan ha realizado tu ruta compartida', CAST(N'2015-11-05 14:56:56.557' AS DateTime), 1, N'2aff6e2d-50fd-4533-8097-8a6db5a1fec1', N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.555&markers=color:red|-33.408,-70.55&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEvgsmL?gE???gE?gE??fEgEgEgE', N'0ccd66b3-092d-4cdd-b733-c57b92e1e31d')
INSERT [dbo].[TB_MOT_Notificacion] ([NOTI_Codigo], [NOTI_USUA_Codigo], [NOTI_TINO_Identificador], [NOTI_Texto], [NOTI_Fecha], [NOTI_Leida], [NOTI_Token], [NOTI_Imagen], [NOTI_Contexto]) VALUES (5, 36, N'INFO', N'Ligia ha usado tu ruta', CAST(N'2015-11-05 18:20:30.627' AS DateTime), 1, N'a3f8844f-ff20-4790-8c54-aabcadb3e675', N'cdb1e951-f5c6-4df4-ba04-68dccaa76a8c', N'0ccd66b3-092d-4cdd-b733-c57b92e1e31d')
INSERT [dbo].[TB_MOT_Notificacion] ([NOTI_Codigo], [NOTI_USUA_Codigo], [NOTI_TINO_Identificador], [NOTI_Texto], [NOTI_Fecha], [NOTI_Leida], [NOTI_Token], [NOTI_Imagen], [NOTI_Contexto]) VALUES (6, 36, N'RUCO', N'Juan ha realizado tu ruta compartida', CAST(N'2015-11-05 18:21:30.627' AS DateTime), 1, N'34dda13a-3a82-4b2d-9309-49aa5fa2f32b', N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.555&markers=color:red|-33.408,-70.55&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEvgsmL?gE???gE?gE??fEgEgEgE', N'0ccd66b3-092d-4cdd-b733-c57b92e1e31d')
SET IDENTITY_INSERT [dbo].[TB_MOT_Notificacion] OFF
SET IDENTITY_INSERT [dbo].[TB_MOT_Ruta] ON 

INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (6, 36, CAST(N'2015-11-01 23:04:10.000' AS DateTime), CAST(N'2015-11-04 23:05:19.000' AS DateTime), 37, 31, CAST(1.13608 AS Decimal(18, 5)), CAST(113.60809 AS Decimal(18, 5)), CAST(18.00000 AS Decimal(18, 5)), 2, N'7e6cb385-43e5-490f-9217-89c465a74042', CAST(-33.407430000 AS Decimal(18, 9)), CAST(-70.547910000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.552&markers=color:red|-33.406,-70.543&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jE~trmL??fEgEgEgE??gE??gE?gE????fE??gE???gE?gEgEgE??gE??gE', CAST(N'2015-11-01 23:04:10.000' AS DateTime), 100)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (7, 36, CAST(N'2015-11-05 23:14:20.000' AS DateTime), CAST(N'2015-11-04 23:14:57.000' AS DateTime), 12, 25, CAST(0.43983 AS Decimal(18, 5)), CAST(143.94556 AS Decimal(18, 5)), CAST(6.00000 AS Decimal(18, 5)), 2, N'5ce548fe-5c69-43c6-ac76-df817922f044', CAST(-33.407680000 AS Decimal(18, 9)), CAST(-70.550040000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.552&markers=color:red|-33.407,-70.548&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jE~trmLfEgEgEgEgE??gE???gE', CAST(N'2015-11-05 23:14:20.000' AS DateTime), 200)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (8, 36, CAST(N'2015-10-29 23:43:02.837' AS DateTime), CAST(N'2015-11-04 23:46:50.923' AS DateTime), 150, 78, CAST(9.96675 AS Decimal(18, 5)), CAST(240.80741 AS Decimal(18, 5)), CAST(80.00000 AS Decimal(18, 5)), 1, N'067742c4-7fe8-47d2-bbfb-d88ffa97fb3d', CAST(-33.394140000 AS Decimal(18, 9)), CAST(-70.527070000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.554&markers=color:red|-33.38,-70.5&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEnasmL?gE?gE??fEgEgEgEgE??gE???gE????fE????gE?gE?gEgEgE??gE??gE?oKgEoK?gEoKgE????gEgEoKgEgEgE?gE?gEgEgEoK?gE?gE?gEgEgE????gEfEgEnK???fE?fE?fE?fEfEfE?nK?fEoK?wj@?wQgEgEoK?oKgEoK???gE?gE?oK?gEoKgEgE?gE?oK??oKoKgEoKgEgEgEgE?vQgE?gE?gE??????oK?oK?gEgEgEgE???', CAST(N'2015-10-29 23:43:02.837' AS DateTime), 100)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (9, 36, CAST(N'2015-10-30 00:17:24.950' AS DateTime), CAST(N'2015-11-05 00:18:04.743' AS DateTime), 13, 19, CAST(0.42726 AS Decimal(18, 5)), CAST(128.17793 AS Decimal(18, 5)), CAST(7.00000 AS Decimal(18, 5)), 2, N'5403733a-eef7-4594-966b-4a4c4d1b0e42', CAST(-33.407710000 AS Decimal(18, 9)), CAST(-70.550770000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.553&markers=color:red|-33.407,-70.548&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEf{rmL?gE??fEgEgEgE??gEgE?gE', CAST(N'2015-10-30 00:17:24.950' AS DateTime), 200)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (10, 36, CAST(N'2015-11-01 00:46:53.360' AS DateTime), CAST(N'2015-11-05 00:47:01.900' AS DateTime), 6, 10, CAST(0.16254 AS Decimal(18, 5)), CAST(117.03170 AS Decimal(18, 5)), CAST(2.00000 AS Decimal(18, 5)), 2, N'eaffcd79-6012-4967-a4ac-c1fe8721306e', CAST(-33.407890000 AS Decimal(18, 9)), CAST(-70.549920000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.55&markers=color:red|-33.407,-70.55&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEnhrmL??gE?', CAST(N'2015-11-01 00:46:53.360' AS DateTime), 100)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (11, 36, CAST(N'2015-11-02 01:21:19.310' AS DateTime), CAST(N'2015-11-05 01:21:35.703' AS DateTime), 11, 2, CAST(0.19236 AS Decimal(18, 5)), CAST(115.41460 AS Decimal(18, 5)), CAST(3.00000 AS Decimal(18, 5)), 1, N'a024b4e7-b0dc-438b-b0c7-31e0eebb9300', CAST(-33.408300000 AS Decimal(18, 9)), CAST(-70.552660000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.554&markers=color:red|-33.408,-70.552&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEnasmL?gE?gE??', CAST(N'2015-11-02 01:21:19.310' AS DateTime), 200)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (12, 36, CAST(N'2015-11-03 01:22:28.623' AS DateTime), CAST(N'2015-11-05 01:22:42.367' AS DateTime), 12, 1, CAST(0.32449 AS Decimal(18, 5)), CAST(116.81789 AS Decimal(18, 5)), CAST(5.00000 AS Decimal(18, 5)), 3, N'000dc457-100f-41de-9929-117f333d34ca', CAST(-33.408200000 AS Decimal(18, 9)), CAST(-70.553360000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.555&markers=color:red|-33.408,-70.552&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEvgsmL?gE???gE?gE??', CAST(N'2015-11-03 01:22:28.623' AS DateTime), 200)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (13, 36, CAST(N'2015-11-04 01:22:28.623' AS DateTime), CAST(N'2015-11-05 01:22:42.367' AS DateTime), 12, 1, CAST(0.32449 AS Decimal(18, 5)), CAST(116.81789 AS Decimal(18, 5)), CAST(5.00000 AS Decimal(18, 5)), 3, N'12c64cd4-a9e4-4976-80cd-de6c545b36de', CAST(-33.408200000 AS Decimal(18, 9)), CAST(-70.553360000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.555&markers=color:red|-33.408,-70.552&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEvgsmL?gE???gE?gE??', CAST(N'2015-11-04 01:22:28.623' AS DateTime), 200)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (14, 36, CAST(N'2015-11-05 01:22:28.623' AS DateTime), CAST(N'2015-11-05 01:22:42.367' AS DateTime), 12, 1, CAST(0.32449 AS Decimal(18, 5)), CAST(116.81789 AS Decimal(18, 5)), CAST(5.00000 AS Decimal(18, 5)), 3, N'953ed62f-a315-4f7b-a2f7-6e7bcaba57f8', CAST(-33.408200000 AS Decimal(18, 9)), CAST(-70.553360000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.555&markers=color:red|-33.408,-70.552&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEvgsmL?gE???gE?gE??', CAST(N'2015-11-05 01:22:28.623' AS DateTime), 100)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (15, 36, CAST(N'2015-11-05 01:22:28.623' AS DateTime), CAST(N'2015-11-05 01:22:42.367' AS DateTime), 12, 1, CAST(0.32449 AS Decimal(18, 5)), CAST(116.81789 AS Decimal(18, 5)), CAST(5.00000 AS Decimal(18, 5)), 3, N'f84fb885-2755-4dc8-9c36-482f80d5cf32', CAST(-33.408200000 AS Decimal(18, 9)), CAST(-70.553360000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.555&markers=color:red|-33.408,-70.552&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEvgsmL?gE???gE?gE??', CAST(N'2015-11-05 01:22:28.623' AS DateTime), 100)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (16, 36, CAST(N'2015-11-05 01:22:28.623' AS DateTime), CAST(N'2015-11-05 01:22:42.367' AS DateTime), 12, 1, CAST(0.32449 AS Decimal(18, 5)), CAST(116.81789 AS Decimal(18, 5)), CAST(5.00000 AS Decimal(18, 5)), 3, N'4d3a8411-3b7b-4c22-8a37-5a8bec059b09', CAST(-33.408200000 AS Decimal(18, 9)), CAST(-70.553360000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.555&markers=color:red|-33.408,-70.552&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEvgsmL?gE???gE?gE??', CAST(N'2015-11-05 01:22:28.623' AS DateTime), 100)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (17, 36, CAST(N'2015-11-05 01:22:28.623' AS DateTime), CAST(N'2015-11-05 01:22:42.367' AS DateTime), 12, 1, CAST(0.32449 AS Decimal(18, 5)), CAST(116.81789 AS Decimal(18, 5)), CAST(5.00000 AS Decimal(18, 5)), 3, N'35129be2-8e7e-44fb-b783-86a1d2dda83f', CAST(-33.408200000 AS Decimal(18, 9)), CAST(-70.553360000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.555&markers=color:red|-33.408,-70.552&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEvgsmL?gE???gE?gE??', CAST(N'2015-11-05 01:22:28.623' AS DateTime), 100)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (18, 36, CAST(N'2015-11-05 01:28:39.180' AS DateTime), CAST(N'2015-11-05 01:29:20.207' AS DateTime), 13, 12, CAST(0.45653 AS Decimal(18, 5)), CAST(136.95878 AS Decimal(18, 5)), CAST(7.00000 AS Decimal(18, 5)), 1, N'0ccd66b3-092d-4cdd-b733-c57b92e1e31d', CAST(-33.408290000 AS Decimal(18, 9)), CAST(-70.552690000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.555&markers=color:red|-33.408,-70.55&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEvgsmL?gE???gE?gE??fEgEgEgE', CAST(N'2015-11-05 01:28:39.180' AS DateTime), 100)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (19, 36, CAST(N'2015-11-05 03:12:00.530' AS DateTime), CAST(N'2015-11-05 03:12:49.363' AS DateTime), 46, 2, CAST(3.36466 AS Decimal(18, 5)), CAST(269.17265 AS Decimal(18, 5)), CAST(21.00000 AS Decimal(18, 5)), 2, N'fa83174b-b7a8-4ac9-8469-2ffea0911353', CAST(-33.396720000 AS Decimal(18, 9)), CAST(-70.520350000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.397,-70.528&markers=color:red|-33.39,-70.512&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:fzyjE~~mmLfE???fEfEfE?nK?fEoK?oK?g^?wQgEgEoK?oKgEoK???gEgE?fEgE?oK?gEgE?gEgEgE', CAST(N'2015-11-05 03:12:00.530' AS DateTime), 200)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (20, 36, CAST(N'2015-11-05 19:36:11.500' AS DateTime), CAST(N'2015-11-05 19:37:27.660' AS DateTime), 58, 13, CAST(1.80198 AS Decimal(18, 5)), CAST(115.84162 AS Decimal(18, 5)), CAST(27.00000 AS Decimal(18, 5)), 2, N'6fbee7df-a18b-4de7-bcf8-cf18cdd39869', CAST(-33.406910000 AS Decimal(18, 9)), CAST(-70.547130000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.555&markers=color:red|-33.405,-70.539&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEvgsmL?gE???gE?gE??fEgEgEgE??gE??gE???gE????fE????gE???gE?gEgEgE??gE??gE?gE?gEgEoK', CAST(N'2015-11-05 19:36:11.500' AS DateTime), 100)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (21, 36, CAST(N'2015-11-06 06:04:08.050' AS DateTime), CAST(N'2015-11-06 06:08:21.123' AS DateTime), 172, 15, CAST(10.15821 AS Decimal(18, 5)), CAST(213.85709 AS Decimal(18, 5)), CAST(88.00000 AS Decimal(18, 5)), 3, N'401c85a1-93e5-4888-9712-960ff26f6fef', CAST(-33.394270000 AS Decimal(18, 9)), CAST(-70.527510000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.408,-70.555&markers=color:red|-33.38,-70.5&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:~~{jEvgsmL?gE???gE?gE??fEgEgEgE??gE??gE???gE????fE????gE???gE?gEgEgE??gE??gE?gE?gEgEoK?gEoKgE????gEgEoKgEgEgE?gE?gEgEgEoK?gE?gE?gEgEgE????gEfEgEnK???fE?fE?fE???fEfEfE?nK?fEoK?oK?g^?wQgEgEoK?oKgEoK???gEgE?fEgE?oK?gEgE?gEgEgE?wQ??oKoKgEoKgEgEgEgE?vQgE?gE??fEgEgE?????oK?oK?gEgEgEgE?', CAST(N'2015-11-06 06:08:44.320' AS DateTime), 100)
INSERT [dbo].[TB_MOT_Ruta] ([RUTA_Codigo], [RUTA_USUA_Codigo], [RUTA_Inicio], [RUTA_Fin], [RUTA_Duracion], [RUTA_Pausas], [RUTA_Distancia], [RUTA_Velocidad], [RUTA_Calorias], [RUTA_TISE_Sensacion], [RUTA_Token], [RUTA_Latitud], [RUTA_Longitud], [RUTA_Altitud], [RUTA_Imagen], [RUTA_Fecha], [RUTA_TIDE_Codigo]) VALUES (22, 36, CAST(N'2015-11-06 13:50:39.227' AS DateTime), CAST(N'2015-11-06 13:51:18.030' AS DateTime), 28, 10, CAST(1.12223 AS Decimal(18, 5)), CAST(144.28619 AS Decimal(18, 5)), CAST(14.00000 AS Decimal(18, 5)), 2, N'85174f3e-6d88-42b0-be83-06b2bf4d04d5', CAST(-33.378580000 AS Decimal(18, 9)), CAST(-70.514600000 AS Decimal(18, 9)), CAST(300.00000 AS Decimal(18, 5)), N'http://maps.google.com/maps/api/staticmap?sensor=false&size=600x600&markers=color:green|-33.381,-70.512&markers=color:red|-33.375,-70.517&maptype=hybrid&path=color:0xffc107FF|weight:5|enc:fvvjE~zjmL?fEfEfE??gE?gE??fE?gEgE?gE??fEgE?gE??fEgEfE', CAST(N'2015-11-06 13:52:06.583' AS DateTime), 100)
SET IDENTITY_INSERT [dbo].[TB_MOT_Ruta] OFF
INSERT [dbo].[TB_MOT_RutaCompartida] ([RUCO_RUTA_Codigo], [RUCO_Nombre], [RUCO_Observaciones], [RUCO_Fecha], [RUCO_MeGusta]) VALUES (17, N'Av. Apoquindo 7280-7338, Las Condes, Las Condes, Región Metropolitana, Chile', NULL, CAST(N'2015-11-04 22:26:35.397' AS DateTime), 0)
INSERT [dbo].[TB_MOT_RutaCompartida] ([RUCO_RUTA_Codigo], [RUCO_Nombre], [RUCO_Observaciones], [RUCO_Fecha], [RUCO_MeGusta]) VALUES (18, N'Av. Apoquindo 7340-7498, Las Condes, Las Condes, Región Metropolitana, Chile', N'Algo que hacer!!', CAST(N'2015-11-04 22:29:30.230' AS DateTime), 0)
INSERT [dbo].[TB_MOT_RutaCompartida] ([RUCO_RUTA_Codigo], [RUCO_Nombre], [RUCO_Observaciones], [RUCO_Fecha], [RUCO_MeGusta]) VALUES (19, N'Ruta Muy Rapida', N'Ruta de Prueba', CAST(N'2015-11-05 00:13:15.493' AS DateTime), 0)
INSERT [dbo].[TB_MOT_RutaCompartida] ([RUCO_RUTA_Codigo], [RUCO_Nombre], [RUCO_Observaciones], [RUCO_Fecha], [RUCO_MeGusta]) VALUES (20, N'Zanzibar Ote 7280, Las Condes, Las Condes, Región Metropolitana, Chile', NULL, CAST(N'2015-11-05 16:37:32.077' AS DateTime), 0)
INSERT [dbo].[TB_MOT_RutaCompartida] ([RUCO_RUTA_Codigo], [RUCO_Nombre], [RUCO_Observaciones], [RUCO_Fecha], [RUCO_MeGusta]) VALUES (21, N'Camino Las Flores 10222, LT 4 D, Las Condes, Las Condes, Región Metropolitana, Chile', N'Primera Ruta , Prueba Completa', CAST(N'2015-11-06 03:08:44.567' AS DateTime), 0)
INSERT [dbo].[TB_MOT_RutaCompartida] ([RUCO_RUTA_Codigo], [RUCO_Nombre], [RUCO_Observaciones], [RUCO_Fecha], [RUCO_MeGusta]) VALUES (22, N'Mi Mejor Ruta!', N'Prueba de comentario', CAST(N'2015-11-06 10:52:06.823' AS DateTime), 0)
INSERT [dbo].[TB_MOT_Siguiendo] ([SIGUI_USUA_Codigo], [SIGUI_USUA_Codigo_Siguiendo]) VALUES (36, 37)
INSERT [dbo].[TB_MOT_Siguiendo] ([SIGUI_USUA_Codigo], [SIGUI_USUA_Codigo_Siguiendo]) VALUES (36, 38)
INSERT [dbo].[TB_MOT_TipoAutenticador] ([TIAU_Identificador], [TIAU_Nombre]) VALUES (N'fbook', N'Facebook')
INSERT [dbo].[TB_MOT_TipoAutenticador] ([TIAU_Identificador], [TIAU_Nombre]) VALUES (N'gmail', N'Google Mail ')
INSERT [dbo].[TB_MOT_TipoDeporte] ([TIDE_Codigo], [TIDE_Nombre], [TIDE_Descripcion]) VALUES (100, N'Enduro', N'Moto Enduro')
INSERT [dbo].[TB_MOT_TipoDeporte] ([TIDE_Codigo], [TIDE_Nombre], [TIDE_Descripcion]) VALUES (200, N'MotoCross', N'Moto de Ruta')
INSERT [dbo].[TB_MOT_TipoNotificacion] ([TINO_Identificador], [TINO_Nombre]) VALUES (N'ASEG', N'Notiificacion para indicar que tiene un nuevo seguidor')
INSERT [dbo].[TB_MOT_TipoNotificacion] ([TINO_Identificador], [TINO_Nombre]) VALUES (N'INFO', N'Información general')
INSERT [dbo].[TB_MOT_TipoNotificacion] ([TINO_Identificador], [TINO_Nombre]) VALUES (N'MEDA', N'Notificación de Medalla')
INSERT [dbo].[TB_MOT_TipoNotificacion] ([TINO_Identificador], [TINO_Nombre]) VALUES (N'RUCO', N'Ruta Compartida')
INSERT [dbo].[TB_MOT_TipoSensacion] ([TISE_Codigo], [TISE_Nombre], [TISE_Token], [TISE_Identificador]) VALUES (1, N'Relajado', N'8a8699d1-a23b-4a20-8fa0-a668cdcca65d', N'RELA')
INSERT [dbo].[TB_MOT_TipoSensacion] ([TISE_Codigo], [TISE_Nombre], [TISE_Token], [TISE_Identificador]) VALUES (2, N'Cansado', N'363eeb79-60d9-4da8-a520-530fa7fc7625', N'CANS')
INSERT [dbo].[TB_MOT_TipoSensacion] ([TISE_Codigo], [TISE_Nombre], [TISE_Token], [TISE_Identificador]) VALUES (3, N'Agotado', N'1d7277c5-16b3-4de9-a038-28c45fa62228', N'AGOT')
/****** Object:  Index [IX_TB_BPM_Bitacora]    Script Date: 06/11/2015 11:15:04 ******/
CREATE NONCLUSTERED INDEX [IX_TB_BPM_Bitacora] ON [dbo].[TB_BPM_Bitacora]
(
	[BITA_DOCU_Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_TB_BPM_Bitacora_1]    Script Date: 06/11/2015 11:15:04 ******/
CREATE NONCLUSTERED INDEX [IX_TB_BPM_Bitacora_1] ON [dbo].[TB_BPM_Bitacora]
(
	[BITA_Fecha] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_TB_BPM_Documento]    Script Date: 06/11/2015 11:15:04 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_TB_BPM_Documento] ON [dbo].[TB_BPM_Documento]
(
	[DOCU_Token] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_TB_BPM_Estado]    Script Date: 06/11/2015 11:15:04 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_TB_BPM_Estado] ON [dbo].[TB_BPM_Estado]
(
	[ESTA_Token] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_TB_BPM_Estado_1]    Script Date: 06/11/2015 11:15:04 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_TB_BPM_Estado_1] ON [dbo].[TB_BPM_Estado]
(
	[ESTA_Identificador] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_TB_BPM_TipoDocumento]    Script Date: 06/11/2015 11:15:04 ******/
CREATE NONCLUSTERED INDEX [IX_TB_BPM_TipoDocumento] ON [dbo].[TB_BPM_TipoDocumento]
(
	[TIDO_Identificador] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_TB_BPM_TipoDocumento_1]    Script Date: 06/11/2015 11:15:04 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_TB_BPM_TipoDocumento_1] ON [dbo].[TB_BPM_TipoDocumento]
(
	[TIDO_Identificador] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_TB_BPM_TipoNotificacion]    Script Date: 06/11/2015 11:15:04 ******/
CREATE NONCLUSTERED INDEX [IX_TB_BPM_TipoNotificacion] ON [dbo].[TB_BPM_TipoNotificacion]
(
	[TINO_Identificador] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_TB_BPM_Transicion]    Script Date: 06/11/2015 11:15:04 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_TB_BPM_Transicion] ON [dbo].[TB_BPM_Transicion]
(
	[TRAN_ESTA_Codigo] ASC,
	[TRAN_Identificador] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_TB_MAE_Entidad]    Script Date: 06/11/2015 11:15:04 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_TB_MAE_Entidad] ON [dbo].[TB_MAE_Entidad]
(
	[ENTI_Identificador] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_TB_MAE_Perfil]    Script Date: 06/11/2015 11:15:04 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_TB_MAE_Perfil] ON [dbo].[TB_MAE_Perfil]
(
	[PERF_Identificador] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_TB_MAE_TipoEntidad]    Script Date: 06/11/2015 11:15:04 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_TB_MAE_TipoEntidad] ON [dbo].[TB_MAE_TipoEntidad]
(
	[TIEN_Identificador] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TB_BPM_Bitacora] ADD  CONSTRAINT [DF__TB_BPM_Bi__BITA___236943A5]  DEFAULT (getdate()) FOR [BITA_Fecha]
GO
ALTER TABLE [dbo].[TB_BPM_Documento] ADD  DEFAULT (getdate()) FOR [DOCU_Fecha]
GO
ALTER TABLE [dbo].[TB_BPM_Documento] ADD  DEFAULT (newid()) FOR [DOCU_Token]
GO
ALTER TABLE [dbo].[TB_BPM_Notificacion] ADD  CONSTRAINT [DF__TB_BPM_No__NOTI___2739D489]  DEFAULT (getdate()) FOR [NOTI_Fecha]
GO
ALTER TABLE [dbo].[TB_BPM_Notificacion] ADD  CONSTRAINT [DF__TB_BPM_No__NOTI___282DF8C2]  DEFAULT (newid()) FOR [NOTI_Token]
GO
ALTER TABLE [dbo].[TB_BPM_Notificacion] ADD  CONSTRAINT [DF__TB_BPM_No__NOTI___29221CFB]  DEFAULT ((0)) FOR [NOTI_Leida]
GO
ALTER TABLE [dbo].[TB_BPM_Tarea] ADD  DEFAULT (getdate()) FOR [TARE_Fecha]
GO
ALTER TABLE [dbo].[TB_BPM_TipoNotificacion] ADD  CONSTRAINT [DF__TB_BPM_Ti__TINO___2BFE89A6]  DEFAULT (newid()) FOR [TINO_Token]
GO
ALTER TABLE [dbo].[TB_BPM_Transicion] ADD  CONSTRAINT [DF__TB_BPM_Tr__TRAN___6166761E]  DEFAULT (newid()) FOR [TRAN_Token]
GO
ALTER TABLE [dbo].[TB_MOT_Comentarios] ADD  CONSTRAINT [DF_TB_MOT_Comentarios_COME_Fecha]  DEFAULT (getdate()) FOR [COME_Fecha]
GO
ALTER TABLE [dbo].[TB_MOT_Foto] ADD  CONSTRAINT [DF_TB_MOT_FotoRuta_FOTO_Portada]  DEFAULT ((0)) FOR [FOTO_Portada]
GO
ALTER TABLE [dbo].[TB_BPM_Bitacora]  WITH CHECK ADD  CONSTRAINT [FK_BPM_Bitacora_BPM_Documento] FOREIGN KEY([BITA_DOCU_Codigo])
REFERENCES [dbo].[TB_BPM_Documento] ([DOCU_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_BPM_Bitacora] CHECK CONSTRAINT [FK_BPM_Bitacora_BPM_Documento]
GO
ALTER TABLE [dbo].[TB_BPM_Bitacora]  WITH CHECK ADD  CONSTRAINT [FK_BPM_Bitacora_BPM_Estado] FOREIGN KEY([BITA_ESTA_Codigo])
REFERENCES [dbo].[TB_BPM_Estado] ([ESTA_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_BPM_Bitacora] CHECK CONSTRAINT [FK_BPM_Bitacora_BPM_Estado]
GO
ALTER TABLE [dbo].[TB_BPM_Bitacora]  WITH CHECK ADD  CONSTRAINT [FK_TB_BPM_Bitacora_TB_MAE_Entidad] FOREIGN KEY([BITA_ENTI_Codigo])
REFERENCES [dbo].[TB_MAE_Entidad] ([ENTI_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_BPM_Bitacora] CHECK CONSTRAINT [FK_TB_BPM_Bitacora_TB_MAE_Entidad]
GO
ALTER TABLE [dbo].[TB_BPM_Documento]  WITH CHECK ADD  CONSTRAINT [FK_BPM_Documento_BPM_Estado] FOREIGN KEY([DOCU_ESTA_Codigo])
REFERENCES [dbo].[TB_BPM_Estado] ([ESTA_Codigo])
GO
ALTER TABLE [dbo].[TB_BPM_Documento] CHECK CONSTRAINT [FK_BPM_Documento_BPM_Estado]
GO
ALTER TABLE [dbo].[TB_BPM_Documento]  WITH CHECK ADD  CONSTRAINT [FK_BPM_Documento_BPM_TipoDocumento] FOREIGN KEY([DOCU_TIDO_Codigo])
REFERENCES [dbo].[TB_BPM_TipoDocumento] ([TIDO_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_BPM_Documento] CHECK CONSTRAINT [FK_BPM_Documento_BPM_TipoDocumento]
GO
ALTER TABLE [dbo].[TB_BPM_Documento]  WITH CHECK ADD  CONSTRAINT [FK_TB_BPM_Documento_TB_MAE_Entidad] FOREIGN KEY([DOCU_ENTI_Codigo])
REFERENCES [dbo].[TB_MAE_Entidad] ([ENTI_Codigo])
GO
ALTER TABLE [dbo].[TB_BPM_Documento] CHECK CONSTRAINT [FK_TB_BPM_Documento_TB_MAE_Entidad]
GO
ALTER TABLE [dbo].[TB_BPM_Estado]  WITH CHECK ADD  CONSTRAINT [FK_TB_Bto] FOREIGN KEY([ESTA_TIDO_Codigo])
REFERENCES [dbo].[TB_BPM_TipoDocumento] ([TIDO_Codigo])
GO
ALTER TABLE [dbo].[TB_BPM_Estado] CHECK CONSTRAINT [FK_TB_Bto]
GO
ALTER TABLE [dbo].[TB_BPM_Notificacion]  WITH CHECK ADD  CONSTRAINT [FK_BPM_Notificaciones_BPM_Documento] FOREIGN KEY([NOTI_DOCU_Codigo])
REFERENCES [dbo].[TB_BPM_Documento] ([DOCU_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_BPM_Notificacion] CHECK CONSTRAINT [FK_BPM_Notificaciones_BPM_Documento]
GO
ALTER TABLE [dbo].[TB_BPM_Notificacion]  WITH CHECK ADD  CONSTRAINT [FK_BPM_Notificaciones_BPM_TipoNotificacion] FOREIGN KEY([NOTI_TINO_Codigo])
REFERENCES [dbo].[TB_BPM_TipoNotificacion] ([TINO_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_BPM_Notificacion] CHECK CONSTRAINT [FK_BPM_Notificaciones_BPM_TipoNotificacion]
GO
ALTER TABLE [dbo].[TB_BPM_Notificacion]  WITH CHECK ADD  CONSTRAINT [FK_TB_BPM_Notificacion_TB_MAE_Entidad] FOREIGN KEY([NOTI_ENTI_Codigo])
REFERENCES [dbo].[TB_MAE_Entidad] ([ENTI_Codigo])
GO
ALTER TABLE [dbo].[TB_BPM_Notificacion] CHECK CONSTRAINT [FK_TB_BPM_Notificacion_TB_MAE_Entidad]
GO
ALTER TABLE [dbo].[TB_BPM_NotificacionTransicion]  WITH CHECK ADD  CONSTRAINT [FK_BPM_ConfiguracionNotificaciones_BPM_TipoNotificacion] FOREIGN KEY([CNOT_TINO_Codigo])
REFERENCES [dbo].[TB_BPM_TipoNotificacion] ([TINO_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_BPM_NotificacionTransicion] CHECK CONSTRAINT [FK_BPM_ConfiguracionNotificaciones_BPM_TipoNotificacion]
GO
ALTER TABLE [dbo].[TB_BPM_NotificacionTransicion]  WITH CHECK ADD  CONSTRAINT [FK_BPM_ConfiguracionNotificaciones_BPM_Transicion] FOREIGN KEY([CNOT_TRAN_Codigo])
REFERENCES [dbo].[TB_BPM_Transicion] ([TRAN_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_BPM_NotificacionTransicion] CHECK CONSTRAINT [FK_BPM_ConfiguracionNotificaciones_BPM_Transicion]
GO
ALTER TABLE [dbo].[TB_BPM_Tarea]  WITH CHECK ADD  CONSTRAINT [FK_BPM_Pendientes_BPM_Documento] FOREIGN KEY([TARE_DOCU_Codigo])
REFERENCES [dbo].[TB_BPM_Documento] ([DOCU_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_BPM_Tarea] CHECK CONSTRAINT [FK_BPM_Pendientes_BPM_Documento]
GO
ALTER TABLE [dbo].[TB_BPM_Tarea]  WITH CHECK ADD  CONSTRAINT [FK_BPM_Pendientes_BPM_Entidad] FOREIGN KEY([TARE_ENTI_Codigo])
REFERENCES [dbo].[TB_MAE_Entidad] ([ENTI_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_BPM_Tarea] CHECK CONSTRAINT [FK_BPM_Pendientes_BPM_Entidad]
GO
ALTER TABLE [dbo].[TB_BPM_Transicion]  WITH CHECK ADD  CONSTRAINT [FK_BPM_Transicion_BPM_Estado] FOREIGN KEY([TRAN_ESTA_Codigo])
REFERENCES [dbo].[TB_BPM_Estado] ([ESTA_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_BPM_Transicion] CHECK CONSTRAINT [FK_BPM_Transicion_BPM_Estado]
GO
ALTER TABLE [dbo].[TB_BPM_Transicion]  WITH CHECK ADD  CONSTRAINT [FK_BPM_Transicion_BPM_Estado1] FOREIGN KEY([TRAN_ESTA_Codigo_Final])
REFERENCES [dbo].[TB_BPM_Estado] ([ESTA_Codigo])
GO
ALTER TABLE [dbo].[TB_BPM_Transicion] CHECK CONSTRAINT [FK_BPM_Transicion_BPM_Estado1]
GO
ALTER TABLE [dbo].[TB_BPM_Transicion]  WITH CHECK ADD  CONSTRAINT [FK_BPM_Transicion_BPM_TipoDocumento] FOREIGN KEY([TRAN_TIDO_Codigo])
REFERENCES [dbo].[TB_BPM_TipoDocumento] ([TIDO_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_BPM_Transicion] CHECK CONSTRAINT [FK_BPM_Transicion_BPM_TipoDocumento]
GO
ALTER TABLE [dbo].[TB_BPM_Transicion]  WITH CHECK ADD  CONSTRAINT [FK_TB_BPM_Transicion_TB_BPM_Entidad] FOREIGN KEY([ENTI_Codigo])
REFERENCES [dbo].[TB_MAE_Entidad] ([ENTI_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_BPM_Transicion] CHECK CONSTRAINT [FK_TB_BPM_Transicion_TB_BPM_Entidad]
GO
ALTER TABLE [dbo].[TB_BPM_TransicionAuxiliar]  WITH CHECK ADD  CONSTRAINT [FK_BPM_ConfiguracionTransicion_BPM_Transicion] FOREIGN KEY([CTRN_TRAN_Codigo])
REFERENCES [dbo].[TB_BPM_Transicion] ([TRAN_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_BPM_TransicionAuxiliar] CHECK CONSTRAINT [FK_BPM_ConfiguracionTransicion_BPM_Transicion]
GO
ALTER TABLE [dbo].[TB_MAE_ArchivoBinario]  WITH CHECK ADD  CONSTRAINT [FK_TB_FileData_TB_File] FOREIGN KEY([ARCH_Codigo])
REFERENCES [dbo].[TB_MAE_Archivo] ([ARCH_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MAE_ArchivoBinario] CHECK CONSTRAINT [FK_TB_FileData_TB_File]
GO
ALTER TABLE [dbo].[TB_MAE_AutenticadorInterno]  WITH CHECK ADD  CONSTRAINT [FK_TB_MAE_AutenticadorInterno_TB_MAE_Usuario] FOREIGN KEY([USUA_Codigo])
REFERENCES [dbo].[TB_MAE_Usuario] ([USUA_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MAE_AutenticadorInterno] CHECK CONSTRAINT [FK_TB_MAE_AutenticadorInterno_TB_MAE_Usuario]
GO
ALTER TABLE [dbo].[TB_MAE_Entidad]  WITH CHECK ADD  CONSTRAINT [FK_v239421] FOREIGN KEY([ENTI_TIEN_Codigo])
REFERENCES [dbo].[TB_MAE_TipoEntidad] ([TIEN_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MAE_Entidad] CHECK CONSTRAINT [FK_v239421]
GO
ALTER TABLE [dbo].[TB_MAE_ItemMenu]  WITH CHECK ADD  CONSTRAINT [FK_Vkasdh33] FOREIGN KEY([MITE_MCAT_Codigo])
REFERENCES [dbo].[TB_MAE_CategoriaMenu] ([MCAT_Codigo])
GO
ALTER TABLE [dbo].[TB_MAE_ItemMenu] CHECK CONSTRAINT [FK_Vkasdh33]
GO
ALTER TABLE [dbo].[TB_MAE_ItemMenu_Perfil]  WITH CHECK ADD  CONSTRAINT [FK_TB_MAE_MenuItem_Perfil_TB_MAE_MenuItem] FOREIGN KEY([MENUPERF_MITE_Codigo])
REFERENCES [dbo].[TB_MAE_ItemMenu] ([MITE_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MAE_ItemMenu_Perfil] CHECK CONSTRAINT [FK_TB_MAE_MenuItem_Perfil_TB_MAE_MenuItem]
GO
ALTER TABLE [dbo].[TB_MAE_ItemMenu_Perfil]  WITH CHECK ADD  CONSTRAINT [FK_TB_MAE_MenuItem_Perfil_TB_MAE_Perfil] FOREIGN KEY([MENUPERF_PERF_Codigo])
REFERENCES [dbo].[TB_MAE_Perfil] ([PERF_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MAE_ItemMenu_Perfil] CHECK CONSTRAINT [FK_TB_MAE_MenuItem_Perfil_TB_MAE_Perfil]
GO
ALTER TABLE [dbo].[TB_MAE_LogError]  WITH CHECK ADD  CONSTRAINT [FK_TB_MAE_LogError_TB_MAE_Entidad] FOREIGN KEY([ELOG_ENTI_Codigo])
REFERENCES [dbo].[TB_MAE_Entidad] ([ENTI_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MAE_LogError] CHECK CONSTRAINT [FK_TB_MAE_LogError_TB_MAE_Entidad]
GO
ALTER TABLE [dbo].[TB_MAE_Perfil]  WITH CHECK ADD  CONSTRAINT [FK_TB_MAE_Perfil_TB_BPM_Entidad] FOREIGN KEY([PERF_Codigo])
REFERENCES [dbo].[TB_MAE_Entidad] ([ENTI_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MAE_Perfil] CHECK CONSTRAINT [FK_TB_MAE_Perfil_TB_BPM_Entidad]
GO
ALTER TABLE [dbo].[TB_MAE_Perfil_Usuario]  WITH CHECK ADD  CONSTRAINT [FK_TB_MAE_Perfil_Usuario_TB_MAE_Perfil] FOREIGN KEY([PUES_PERF_Codigo])
REFERENCES [dbo].[TB_MAE_Perfil] ([PERF_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MAE_Perfil_Usuario] CHECK CONSTRAINT [FK_TB_MAE_Perfil_Usuario_TB_MAE_Perfil]
GO
ALTER TABLE [dbo].[TB_MAE_Perfil_Usuario]  WITH CHECK ADD  CONSTRAINT [FK_TB_MAE_Perfil_Usuario_TB_MAE_Usuario] FOREIGN KEY([PEUS_USUA_Codigo])
REFERENCES [dbo].[TB_MAE_Usuario] ([USUA_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MAE_Perfil_Usuario] CHECK CONSTRAINT [FK_TB_MAE_Perfil_Usuario_TB_MAE_Usuario]
GO
ALTER TABLE [dbo].[TB_MAE_Usuario]  WITH CHECK ADD  CONSTRAINT [FK_TB_MAE_Usuario_TB_BPM_Entidad] FOREIGN KEY([USUA_Codigo])
REFERENCES [dbo].[TB_MAE_Entidad] ([ENTI_Codigo])
GO
ALTER TABLE [dbo].[TB_MAE_Usuario] CHECK CONSTRAINT [FK_TB_MAE_Usuario_TB_BPM_Entidad]
GO
ALTER TABLE [dbo].[TB_MAE_Usuario]  WITH CHECK ADD  CONSTRAINT [FK_TB_MAE_Usuario_TB_MAE_Archivo] FOREIGN KEY([USUA_ARCH_Codigo])
REFERENCES [dbo].[TB_MAE_Archivo] ([ARCH_Codigo])
ON DELETE SET NULL
GO
ALTER TABLE [dbo].[TB_MAE_Usuario] CHECK CONSTRAINT [FK_TB_MAE_Usuario_TB_MAE_Archivo]
GO
ALTER TABLE [dbo].[TB_MAE_Usuario]  WITH CHECK ADD  CONSTRAINT [FK_TB_MAE_Usuario_TB_MOT_TipoDeporte] FOREIGN KEY([USUA_TIDE_Codigo])
REFERENCES [dbo].[TB_MOT_TipoDeporte] ([TIDE_Codigo])
GO
ALTER TABLE [dbo].[TB_MAE_Usuario] CHECK CONSTRAINT [FK_TB_MAE_Usuario_TB_MOT_TipoDeporte]
GO
ALTER TABLE [dbo].[TB_MOT_AutenticadorExterno]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_AutenticadorExterno_TB_MAE_Usuario] FOREIGN KEY([AEXT_USUA_Codigo])
REFERENCES [dbo].[TB_MAE_Usuario] ([USUA_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MOT_AutenticadorExterno] CHECK CONSTRAINT [FK_TB_MOT_AutenticadorExterno_TB_MAE_Usuario]
GO
ALTER TABLE [dbo].[TB_MOT_AutenticadorExterno]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_AutenticadorExterno_TB_MOT_TipoAutenticador] FOREIGN KEY([AEXT_TIAU_Identificador])
REFERENCES [dbo].[TB_MOT_TipoAutenticador] ([TIAU_Identificador])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MOT_AutenticadorExterno] CHECK CONSTRAINT [FK_TB_MOT_AutenticadorExterno_TB_MOT_TipoAutenticador]
GO
ALTER TABLE [dbo].[TB_MOT_Comentarios]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_Comentarios_TB_MAE_Usuario] FOREIGN KEY([COME_USUA_Codigo])
REFERENCES [dbo].[TB_MAE_Usuario] ([USUA_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MOT_Comentarios] CHECK CONSTRAINT [FK_TB_MOT_Comentarios_TB_MAE_Usuario]
GO
ALTER TABLE [dbo].[TB_MOT_Comentarios]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_Comentarios_TB_MAE_Usuario1] FOREIGN KEY([COME_USUA_Codigo])
REFERENCES [dbo].[TB_MAE_Usuario] ([USUA_Codigo])
GO
ALTER TABLE [dbo].[TB_MOT_Comentarios] CHECK CONSTRAINT [FK_TB_MOT_Comentarios_TB_MAE_Usuario1]
GO
ALTER TABLE [dbo].[TB_MOT_ContadorSocial]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_ContadorSocial_TB_MAE_Usuario] FOREIGN KEY([SOCU_USUA_Codigo])
REFERENCES [dbo].[TB_MAE_Usuario] ([USUA_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MOT_ContadorSocial] CHECK CONSTRAINT [FK_TB_MOT_ContadorSocial_TB_MAE_Usuario]
GO
ALTER TABLE [dbo].[TB_MOT_Coordenada]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_Coordenada_TB_MOT_Ruta] FOREIGN KEY([COOR_RUTA_Codigo])
REFERENCES [dbo].[TB_MOT_Ruta] ([RUTA_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MOT_Coordenada] CHECK CONSTRAINT [FK_TB_MOT_Coordenada_TB_MOT_Ruta]
GO
ALTER TABLE [dbo].[TB_MOT_Foto]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_Foto_TB_MOT_Ruta] FOREIGN KEY([FOTO_RUTA_Codigo])
REFERENCES [dbo].[TB_MOT_Ruta] ([RUTA_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MOT_Foto] CHECK CONSTRAINT [FK_TB_MOT_Foto_TB_MOT_Ruta]
GO
ALTER TABLE [dbo].[TB_MOT_Foto]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_FotoRuta_TB_MAE_Archivo] FOREIGN KEY([FOTO_ARCH_Codigo])
REFERENCES [dbo].[TB_MAE_Archivo] ([ARCH_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MOT_Foto] CHECK CONSTRAINT [FK_TB_MOT_FotoRuta_TB_MAE_Archivo]
GO
ALTER TABLE [dbo].[TB_MOT_MeGusta]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_MeGusta_TB_MAE_Usuario] FOREIGN KEY([RUCO_USUA_codigo])
REFERENCES [dbo].[TB_MAE_Usuario] ([USUA_Codigo])
GO
ALTER TABLE [dbo].[TB_MOT_MeGusta] CHECK CONSTRAINT [FK_TB_MOT_MeGusta_TB_MAE_Usuario]
GO
ALTER TABLE [dbo].[TB_MOT_MeGusta]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_MeGusta_TB_MOT_RutaCompartida] FOREIGN KEY([RUCO_RUTA_Codigo])
REFERENCES [dbo].[TB_MOT_RutaCompartida] ([RUCO_RUTA_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MOT_MeGusta] CHECK CONSTRAINT [FK_TB_MOT_MeGusta_TB_MOT_RutaCompartida]
GO
ALTER TABLE [dbo].[TB_MOT_Notificacion]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_Notificacion_TB_MAE_Usuario] FOREIGN KEY([NOTI_USUA_Codigo])
REFERENCES [dbo].[TB_MAE_Usuario] ([USUA_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MOT_Notificacion] CHECK CONSTRAINT [FK_TB_MOT_Notificacion_TB_MAE_Usuario]
GO
ALTER TABLE [dbo].[TB_MOT_Notificacion]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_Notificacion_TB_MOT_TipoNotificacion] FOREIGN KEY([NOTI_TINO_Identificador])
REFERENCES [dbo].[TB_MOT_TipoNotificacion] ([TINO_Identificador])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MOT_Notificacion] CHECK CONSTRAINT [FK_TB_MOT_Notificacion_TB_MOT_TipoNotificacion]
GO
ALTER TABLE [dbo].[TB_MOT_Ruta]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_Ruta_TB_MAE_Usuario] FOREIGN KEY([RUTA_USUA_Codigo])
REFERENCES [dbo].[TB_MAE_Usuario] ([USUA_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MOT_Ruta] CHECK CONSTRAINT [FK_TB_MOT_Ruta_TB_MAE_Usuario]
GO
ALTER TABLE [dbo].[TB_MOT_Ruta]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_Ruta_TB_MOT_TipoDeporte] FOREIGN KEY([RUTA_TIDE_Codigo])
REFERENCES [dbo].[TB_MOT_TipoDeporte] ([TIDE_Codigo])
GO
ALTER TABLE [dbo].[TB_MOT_Ruta] CHECK CONSTRAINT [FK_TB_MOT_Ruta_TB_MOT_TipoDeporte]
GO
ALTER TABLE [dbo].[TB_MOT_Ruta]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_Ruta_TB_MOT_TipoSensacion] FOREIGN KEY([RUTA_TISE_Sensacion])
REFERENCES [dbo].[TB_MOT_TipoSensacion] ([TISE_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MOT_Ruta] CHECK CONSTRAINT [FK_TB_MOT_Ruta_TB_MOT_TipoSensacion]
GO
ALTER TABLE [dbo].[TB_MOT_RutaCompartida]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_RutaCompartida_TB_MOT_Ruta] FOREIGN KEY([RUCO_RUTA_Codigo])
REFERENCES [dbo].[TB_MOT_Ruta] ([RUTA_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MOT_RutaCompartida] CHECK CONSTRAINT [FK_TB_MOT_RutaCompartida_TB_MOT_Ruta]
GO
ALTER TABLE [dbo].[TB_MOT_Seguidor]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_Seguidor_TB_MAE_Usuario] FOREIGN KEY([SEGU_USUA_Codigo])
REFERENCES [dbo].[TB_MAE_Usuario] ([USUA_Codigo])
GO
ALTER TABLE [dbo].[TB_MOT_Seguidor] CHECK CONSTRAINT [FK_TB_MOT_Seguidor_TB_MAE_Usuario]
GO
ALTER TABLE [dbo].[TB_MOT_Seguidor]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_Seguidor_TB_MAE_Usuario1] FOREIGN KEY([SEGU_USUA_Codigo_Seguidor])
REFERENCES [dbo].[TB_MAE_Usuario] ([USUA_Codigo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TB_MOT_Seguidor] CHECK CONSTRAINT [FK_TB_MOT_Seguidor_TB_MAE_Usuario1]
GO
ALTER TABLE [dbo].[TB_MOT_Siguiendo]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_Siguiendo_TB_MAE_Usuario] FOREIGN KEY([SIGUI_USUA_Codigo])
REFERENCES [dbo].[TB_MAE_Usuario] ([USUA_Codigo])
GO
ALTER TABLE [dbo].[TB_MOT_Siguiendo] CHECK CONSTRAINT [FK_TB_MOT_Siguiendo_TB_MAE_Usuario]
GO
ALTER TABLE [dbo].[TB_MOT_Siguiendo]  WITH CHECK ADD  CONSTRAINT [FK_TB_MOT_Siguiendo_TB_MAE_Usuario1] FOREIGN KEY([SIGUI_USUA_Codigo_Siguiendo])
REFERENCES [dbo].[TB_MAE_Usuario] ([USUA_Codigo])
GO
ALTER TABLE [dbo].[TB_MOT_Siguiendo] CHECK CONSTRAINT [FK_TB_MOT_Siguiendo_TB_MAE_Usuario1]
GO
/****** Object:  Trigger [dbo].[TR_DEL_TB_MAE_Perfil]    Script Date: 06/11/2015 11:15:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[TR_DEL_TB_MAE_Perfil] ON [dbo].[TB_MAE_Perfil] FOR DELETE
AS 
	-- SE INTENTA REMOVER EL REGISTRO DE LA ENTIDAD 
	DELETE FROM 
		TB_MAE_Entidad
    WHERE 
		ENTI_Codigo IN(SELECT deleted.PERF_Codigo FROM deleted)


GO
/****** Object:  Trigger [dbo].[TR_DEL_TB_MAE_Usuario]    Script Date: 06/11/2015 11:15:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TR_DEL_TB_MAE_Usuario] ON [dbo].[TB_MAE_Usuario] FOR DELETE
AS 
	-- SE INTENTA REMOVER EL REGISTRO DE LA ENTIDAD 
	DELETE FROM 
		TB_MAE_Entidad
    WHERE 
		ENTI_Codigo IN(SELECT deleted.USUA_Codigo FROM deleted)

GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Bitacora', @level2type=N'COLUMN',@level2name=N'BITA_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Estado Historico del cambio' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Bitacora', @level2type=N'COLUMN',@level2name=N'BITA_ESTA_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Documento asociado al cambio' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Bitacora', @level2type=N'COLUMN',@level2name=N'BITA_DOCU_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Entidad que realizo el cambio' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Bitacora', @level2type=N'COLUMN',@level2name=N'BITA_ENTI_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha de la bitacora' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Bitacora', @level2type=N'COLUMN',@level2name=N'BITA_Fecha'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Observación opcional del cambio' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Bitacora', @level2type=N'COLUMN',@level2name=N'BITA_Observacion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Historial de cambios de estado que sufre un documento en su ciclo de vida.
Contiene informacion de auditoria sobre los estados por los cuales paso una entidad de negocios.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Bitacora'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Documento', @level2type=N'COLUMN',@level2name=N'DOCU_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Estado actual del documento' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Documento', @level2type=N'COLUMN',@level2name=N'DOCU_ESTA_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tipo de Documento' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Documento', @level2type=N'COLUMN',@level2name=N'DOCU_TIDO_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Entidad que genero el documento' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Documento', @level2type=N'COLUMN',@level2name=N'DOCU_ENTI_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador Grafico del documento' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Documento', @level2type=N'COLUMN',@level2name=N'DOCU_Identificador'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha de creación del documento' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Documento', @level2type=N'COLUMN',@level2name=N'DOCU_Fecha'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Token de la tabla (GUID)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Documento', @level2type=N'COLUMN',@level2name=N'DOCU_Token'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tabla Base que contiene los documentos asociados al sistema.
Un documento es cualquier entidad de negocios del sistema.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Documento'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Estado', @level2type=N'COLUMN',@level2name=N'ESTA_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tipo de Documento asociado al estado disponible por el que podria pasar un documento' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Estado', @level2type=N'COLUMN',@level2name=N'ESTA_TIDO_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre del estado' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Estado', @level2type=N'COLUMN',@level2name=N'ESTA_Nombre'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Token de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Estado', @level2type=N'COLUMN',@level2name=N'ESTA_Token'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Descripcion breve del estado' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Estado', @level2type=N'COLUMN',@level2name=N'ESTA_Descripcion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador del estado' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Estado', @level2type=N'COLUMN',@level2name=N'ESTA_Identificador'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Estado disponibles de  los documentos. Basicamente contiene el listado de acciones disponibles (estados) para cada estado particular del documento en el flujo.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Estado'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Notificacion', @level2type=N'COLUMN',@level2name=N'NOTI_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Documento asociado a la notificacion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Notificacion', @level2type=N'COLUMN',@level2name=N'NOTI_DOCU_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tipo de Notificacion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Notificacion', @level2type=N'COLUMN',@level2name=N'NOTI_TINO_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Entidad asociada a la notificacion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Notificacion', @level2type=N'COLUMN',@level2name=N'NOTI_ENTI_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Texto ya compilado de la plantilla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Notificacion', @level2type=N'COLUMN',@level2name=N'NOTI_Texto'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha de la notificacion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Notificacion', @level2type=N'COLUMN',@level2name=N'NOTI_Fecha'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Token de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Notificacion', @level2type=N'COLUMN',@level2name=N'NOTI_Token'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indica si la notificacion fue leida o revisada por el usuario' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Notificacion', @level2type=N'COLUMN',@level2name=N'NOTI_Leida'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Contiene las notificaciones actuales de los usuarios, que son visualizadas a traves de la bandeja de entrada del sistema.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Notificacion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_NotificacionTransicion', @level2type=N'COLUMN',@level2name=N'CNOT_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tipo de Notificación configurada para la transicion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_NotificacionTransicion', @level2type=N'COLUMN',@level2name=N'CNOT_TINO_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Transacción asociada a la notificación' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_NotificacionTransicion', @level2type=N'COLUMN',@level2name=N'CNOT_TRAN_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Plantilla que se interpolara una vez ejecutada la transicion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_NotificacionTransicion', @level2type=N'COLUMN',@level2name=N'CNOT_Plantilla'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Contiene las notificaciones asociadas a una transicion,
Cuando se ejecuta una acción de transicion sobre un documento, si existen tareas pendientes para una entidad, lo ideal es que notifique de esto a traves del sistema de notificaciones.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_NotificacionTransicion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Tarea', @level2type=N'COLUMN',@level2name=N'TARE_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Documento asociado a la tarea' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Tarea', @level2type=N'COLUMN',@level2name=N'TARE_DOCU_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Entidad asignada a la tarea' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Tarea', @level2type=N'COLUMN',@level2name=N'TARE_ENTI_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha de la tarea' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Tarea', @level2type=N'COLUMN',@level2name=N'TARE_Fecha'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Dirección relativa de la pagina a la cual tiene asignada la tarea' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Tarea', @level2type=N'COLUMN',@level2name=N'TARE_Url'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Listado de Tareas pendientes asociadas a las entidades, cuando un documento sufre un cambio de estado.
Si un documento sufre un cambio de estado ,es posible que se active una tarea pendiente a realizar por una entidad (usuario, perfil, etc.) , de ser asi , se debe registrar en esta tabla.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Tarea'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TipoDocumento', @level2type=N'COLUMN',@level2name=N'TIDO_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre del tipo de documento' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TipoDocumento', @level2type=N'COLUMN',@level2name=N'TIDO_Nombre'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Descripcion del tipo de documento' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TipoDocumento', @level2type=N'COLUMN',@level2name=N'TIDO_Descripcion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador del Tipo de documento' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TipoDocumento', @level2type=N'COLUMN',@level2name=N'TIDO_Identificador'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Token de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TipoDocumento', @level2type=N'COLUMN',@level2name=N'TIDO_Token'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tipo de Entidades de Negocios, disponibles para el proyecto.
Contiene los tipos de documentos disponibles en el sistema.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TipoDocumento'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la transicion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TipoNotificacion', @level2type=N'COLUMN',@level2name=N'TINO_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tipo de la noticacion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TipoNotificacion', @level2type=N'COLUMN',@level2name=N'TINO_Identificador'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre del tipo de notificacion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TipoNotificacion', @level2type=N'COLUMN',@level2name=N'TINO_Nombre'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Token de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TipoNotificacion', @level2type=N'COLUMN',@level2name=N'TINO_Token'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Contiene los Tipos de notificaciónes disponibles. 
Sirve para claisificar una notificacion, de acuerdo a una categoria y dependen del proyecto.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TipoNotificacion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Transicion', @level2type=N'COLUMN',@level2name=N'TRAN_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Codigo que debera tener el documento para poder ejecutar la transicion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Transicion', @level2type=N'COLUMN',@level2name=N'TRAN_ESTA_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Codigo del estado final que tendra el documento una vez ejecutada la transición' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Transicion', @level2type=N'COLUMN',@level2name=N'TRAN_ESTA_Codigo_Final'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tipo de Documento asociado a la transicion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Transicion', @level2type=N'COLUMN',@level2name=N'TRAN_TIDO_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Entidad a la cual se le asignara la tarea pendiente (de no haber , el documento pasara a un estado final)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Transicion', @level2type=N'COLUMN',@level2name=N'ENTI_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre de la transicion asociado' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Transicion', @level2type=N'COLUMN',@level2name=N'TRAN_Nombre'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Dirección URL asociada a la transicion a la cual sera asignada la tarea' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Transicion', @level2type=N'COLUMN',@level2name=N'TRAN_Url'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la transicion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Transicion', @level2type=N'COLUMN',@level2name=N'TRAN_Identificador'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Token del identificador' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Transicion', @level2type=N'COLUMN',@level2name=N'TRAN_Token'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Configuracion de transiciones disponibles que indica de acuerdo al estado actual del documento , sus posibles cambios de estado.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_Transicion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TransicionAuxiliar', @level2type=N'COLUMN',@level2name=N'CTRN_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Transacción asociada a los procedimientos que correran una vez ejecutada la transicion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TransicionAuxiliar', @level2type=N'COLUMN',@level2name=N'CTRN_TRAN_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Procedimiento que sera ejecutado una vez la transicion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TransicionAuxiliar', @level2type=N'COLUMN',@level2name=N'CTRN_Procedimiento'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Contiene un listado de procedimientos auxiliar que se ejecutaran una vez se haya producido un cambio de estado del documento a traves de una transicion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_BPM_TransicionAuxiliar'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Archivo', @level2type=N'COLUMN',@level2name=N'ARCH_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre del archivo' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Archivo', @level2type=N'COLUMN',@level2name=N'ARCH_Nombre'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tamano en Bytes' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Archivo', @level2type=N'COLUMN',@level2name=N'ARCH_Tamano'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha de Creacion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Archivo', @level2type=N'COLUMN',@level2name=N'ARCH_FechaCreacion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tipo de contenido asociado al archivo' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Archivo', @level2type=N'COLUMN',@level2name=N'ARCH_ContentType'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Marca que indica si el archivo es temporal' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Archivo', @level2type=N'COLUMN',@level2name=N'ARCH_Temporal'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Token de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Archivo', @level2type=N'COLUMN',@level2name=N'ARCH_Token'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Contiene el listado de archivos registrado en el sistema.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Archivo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_ArchivoBinario', @level2type=N'COLUMN',@level2name=N'ARCH_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Contenido del archivo' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_ArchivoBinario', @level2type=N'COLUMN',@level2name=N'ARCH_Binario'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Contiene el contenido binario de un archivo registrado en el sistema' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_ArchivoBinario'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Hash de la clave del usuario (MD5)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_AutenticadorInterno', @level2type=N'COLUMN',@level2name=N'USUA_Contrasena'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_CategoriaMenu', @level2type=N'COLUMN',@level2name=N'MCAT_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre de la categoria' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_CategoriaMenu', @level2type=N'COLUMN',@level2name=N'MCAT_Nombre'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Token de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_CategoriaMenu', @level2type=N'COLUMN',@level2name=N'MCAT_Token'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Categoria de cada uno de los items de menu' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_CategoriaMenu'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Entidad', @level2type=N'COLUMN',@level2name=N'ENTI_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tipo de Entidad' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Entidad', @level2type=N'COLUMN',@level2name=N'ENTI_TIEN_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Token de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Entidad', @level2type=N'COLUMN',@level2name=N'ENTI_Token'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha de creacion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Entidad', @level2type=N'COLUMN',@level2name=N'ENTI_FechaCreacion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador unico de la entidad' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Entidad', @level2type=N'COLUMN',@level2name=N'ENTI_Identificador'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tabla base que contiene cada una de las entidades que interactuan con el sistema (usuarios, perfiles, etc).
Si un objeto de negocios interactua con los documentos del sistema, debe estar registrado en esta tabla.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Entidad'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_ItemMenu', @level2type=N'COLUMN',@level2name=N'MITE_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Categoria del menu' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_ItemMenu', @level2type=N'COLUMN',@level2name=N'MITE_MCAT_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre del item' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_ItemMenu', @level2type=N'COLUMN',@level2name=N'MITE_Nombre'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'URL relativa (o ruta) del item' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_ItemMenu', @level2type=N'COLUMN',@level2name=N'MITE_Url'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'icono en formato (categoria:icono)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_ItemMenu', @level2type=N'COLUMN',@level2name=N'MITE_Icono'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Ordinal del menu' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_ItemMenu', @level2type=N'COLUMN',@level2name=N'MITE_Ordinal'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Item de  menu , que se presenta en la barra de navegacion del sistema' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_ItemMenu'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Items de menu asociados al perfil especifico' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_ItemMenu_Perfil'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_LogError', @level2type=N'COLUMN',@level2name=N'ELOG_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Entidad a la cual se le produjo el error' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_LogError', @level2type=N'COLUMN',@level2name=N'ELOG_ENTI_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tipo de Error' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_LogError', @level2type=N'COLUMN',@level2name=N'ELOG_Tipo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Pila del error' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_LogError', @level2type=N'COLUMN',@level2name=N'ELOG_Pila'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha de creacion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_LogError', @level2type=N'COLUMN',@level2name=N'ELOG_Fecha'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Contiene un registro de error del sistema, indicando el tipo de error producido y su información base.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_LogError'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Perfil', @level2type=N'COLUMN',@level2name=N'PERF_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Descripcion breve' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Perfil', @level2type=N'COLUMN',@level2name=N'PERF_Descripcion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador unico del perfil' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Perfil', @level2type=N'COLUMN',@level2name=N'PERF_Identificador'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Entidades de Tipo Perfil, y describe los niveles de acceso que tiene una entidad en el sistema.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Perfil'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Usuario asociado al perfil' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Perfil_Usuario', @level2type=N'COLUMN',@level2name=N'PEUS_USUA_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Perfil asociado ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Perfil_Usuario', @level2type=N'COLUMN',@level2name=N'PUES_PERF_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tabla Nap que relaciona las entidades de tipo perfil con las entidades de tipo usuario.
Indica los niveles de acceso que tiene un usuario en el sistema.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Perfil_Usuario'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_TipoEntidad', @level2type=N'COLUMN',@level2name=N'TIEN_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Codigo unico asociado al tipo de entidad' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_TipoEntidad', @level2type=N'COLUMN',@level2name=N'TIEN_Identificador'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre del tipo de entidad' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_TipoEntidad', @level2type=N'COLUMN',@level2name=N'TIEN_Nombre'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Descripcion Breve' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_TipoEntidad', @level2type=N'COLUMN',@level2name=N'TIEN_Descripcion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Token de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_TipoEntidad', @level2type=N'COLUMN',@level2name=N'TIEN_Token'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Contiene los tipos de entidades disponibles en el sistema.
Una entidad es cualquier entidad de negocio que interactue con el sistema, y que tenga interacción con uno o mas documentos del sistema.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_TipoEntidad'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Usuario', @level2type=N'COLUMN',@level2name=N'USUA_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Imagen del usuario (Avatar)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Usuario', @level2type=N'COLUMN',@level2name=N'USUA_ARCH_Codigo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indica si el usuario se encuentra activo en el sistema' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Usuario', @level2type=N'COLUMN',@level2name=N'USUA_Activo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Ultima conexion del usuario ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Usuario', @level2type=N'COLUMN',@level2name=N'USUA_UltimaConexion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Correo electronico asociado al usuario' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Usuario', @level2type=N'COLUMN',@level2name=N'USUA_Email'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Contiene los usuarios (entidades) del sistema' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MAE_Usuario'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Contiene el contexto de la notificacion (puede ser el token del usuario, el token de la ruta, etc)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_MOT_Notificacion', @level2type=N'COLUMN',@level2name=N'NOTI_Contexto'
GO
ALTER DATABASE [MotoApp_v1] SET  READ_WRITE 
GO
