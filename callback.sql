USE [PKGameStat]
GO
/****** Object:  StoredProcedure [dbo].[Game_WEB_Pay_Update_CallBackEx]    Script Date: 2018/9/7 18:02:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


----------------------------------------------------------------------------------------------------
/*
declare @ret int
exec Game_WEB_Pay_Update_CallBackEx '20180904166297','','','',29,6,@ret out
select @ret
*/
-- ��ֵ��������
ALTER PROC [dbo].[Game_WEB_Pay_Update_CallBackEx]
	@sOrderNum varchar(30),
	@sOrderOut varchar(50),
	@Param1 varchar(256),
	@Param2 varchar(64),
	@PayType int,
	@fRmb float,
	@Ret bigint output
	--with encryption 
AS
BEGIN
	Set @Ret=-1


	Declare  @IntOrderID BIGINT,@RecvJD bigint,@RecvJB bigint,@UserID bigint,@vipType int,@vipDays int,@PDate datetime,@ReceiveTimeS datetime,@ReceiveTimeE datetime
			,@subRmb float,@SubPayType int,@GetJB bigint,@SPayType int,@CDate datetime,@Remark varchar(32),@PropID int,@Price float,@day int,@monthCardPrice FLOAT,@matchTicket INT=0          
	Set @vipType=0
	Set @vipDays=0
	Set @SPayType=0

	select @UserID=UserID,@subRmb=SubRmb,@SPayType=PayType,@SubPayType=SubType,@CDate=CDate,@Remark=remark from dbo.GQ_GamePayLog with(nolock)Where OrderNum=@sOrderNum
	if(@PayType not in(3,5,22,17) and @subRmb<>@fRmb)
	begin
		set @Ret=-2 --����ȷ
		return
	end

	if @SPayType<>@PayType
	Begin
		Insert Into [dbo].[GQ_GamePay_YCLog](OrderNum,SubPayType,PayType)
			values(@sOrderNum,@SPayType,@PayType)

		if @PayType=18
		begin
			set @Ret=-2 --����ȷ
			return
		end

		Set @PayType=@SPayType
	End

	if @PayType in(18,23,22,41)
	begin
		--if @PayType=18 and DATEDIFF(SECOND,@CDate,GETDATE())>60*60
		--Begin
		--	Set @Ret=-2
		--	return
		--End
	
		if exists(select 1 from GQ_GamePayLog with(nolock) Where OrderOut=@sOrderOut)
		begin
			Set @Ret=-3
			return
		end
	end

	
	If @PayType in(22) --�Ա�ֱ��
	Begin
		Select @vipType=VipType,@vipDays=VipDays From GQ_GamePay_Config with(nolock)Where Rmb=@subRmb and PayType=0
	End
	Else If @PayType in(18)
	Begin
		Select @vipType=VipType,@vipDays=VipDays,@GetJB=RecvJB From GQ_GamePay_Config with(nolock)Where Rmb=@subRmb and PayType=@PayType
		SELECT @matchTicket=matchTicket FROM GQ_GamePay_ExtraGift_Config WITH(NOLOCK) WHERE Rmb=@subRmb and PayType=@PayType
	END
	Else If @PayType in(4) --�̻�����
	Begin
		Select @vipType=VipType,@vipDays=VipDays From GQ_GamePay_Config with(nolock)Where Rmb=@fRmb and PayType=@PayType
		Select @matchTicket=matchTicket From GQ_GamePay_ExtraGift_Config with(nolock)Where Rmb=@fRmb and PayType=0
	END
	Else
	Begin
		Select @vipType=VipType,@vipDays=VipDays From GQ_GamePay_Config with(nolock)Where Rmb=@fRmb  and PayType=0
		SELECT @matchTicket=matchTicket FROM GQ_GamePay_ExtraGift_Config WITH(NOLOCK) WHERE Rmb=@fRmb and PayType=0
	End
	
	Select @RecvJB=@fRmb*10000 --From GQ_GamePay_Config Where @PayType=PayType and Rmb=@fRmb
	If @PayType=1 or @PayType=2 or @PayType=8 or @PayType=17 or @PayType=29
	Begin
		If @fRmb in(29,99,299,199,1999)
		begin
			Select @RecvJB=(@fRmb+1)*6000
		end
		else if GETDATE()<'2014-02-08'
		begin
			Select @RecvJB=@fRmb*11000
		end
	End
	Else If @PayType in(4,11,12,24,30,32,39,60)
	Begin
		Select @RecvJB=@fRmb*6000
		if GETDATE()<'2016-10-17' and @PayType=39
		begin
			Select @RecvJB=@fRmb*10000
		end
	End
	Else If @PayType in(22)
	Begin
		Select @RecvJB=@subRmb*10000
	End
	Else If @PayType in(27)
	Begin
		Select @RecvJB=@subRmb*10500
	End
	Else If @PayType in(18)
	Begin
		Select @RecvJB=@GetJB
	End
	Else If @PayType in(36)
	Begin
		Select @RecvJB=GetJB From Game_Phone_PayConfig with(nolock) where GameId=0 and unionid=0 and siteid=0 and Rmb=@fRmb
	End

	/*VIP��*/
	If @SubPayType in(10000,10001)
	Begin
		Select @vipType=VipType,@vipDays=VipDays,@RecvJB=RecvJB From GQ_GamePay_Config with(nolock)Where Rmb=@fRmb  and PayType=@SubPayType
		SET @matchTicket=0
	End
	else if @SubPayType=10004
	begin
		set @RecvJB=0
		If @PayType in(18)
		begin
			Select @vipType=VipType,@vipDays=VipDays,@RecvJD=RecvJB From GQ_GamePay_Config with(nolock)Where Rmb=@fRmb  and PayType=10007
			Select @matchTicket=matchTicket FROM GQ_GamePay_ExtraGift_Config with(nolock)Where Rmb=@fRmb and PayType=10007
		end
		else
		begin
			Select @vipType=VipType,@vipDays=VipDays,@RecvJD=RecvJB From GQ_GamePay_Config with(nolock)Where Rmb=@fRmb and PayType=@SubPayType
			Select @matchTicket=matchTicket FROM GQ_GamePay_ExtraGift_Config with(nolock)Where Rmb=@fRmb and PayType=@SubPayType
		end
	end
	Else If @SubPayType in(10002,10003) --����  �����׳����
	Begin
		if @SubPayType=10003 and cast(@Remark as int)=618
		begin
			Set @Remark='1'
		end
		Select @PropID=PropID,@RecvJB=Amount,@Price=Price,@vipType=VipType,@vipDays=VipDays FROM T_Activity_Panicbuying_Product Where SysID=cast(@Remark as int)
		If @Price<>@fRmb
		Begin
			set @Ret=-2 --����ȷ
			return
		END

		SET @matchTicket=0
		IF @SubPayType=10003  
		BEGIN
			Select @matchTicket=matchTicket FROM GQ_GamePay_ExtraGift_Config with(nolock)Where Rmb=@fRmb and PayType=10003
		END      
	End
	else if @SubPayType  in (51804,10009,10010)
	begin
		DECLARE @temp TABLE(userid bigint,[type] int,subtype int,addtime datetime)
		DECLARE @sql varchar(500)
		Set @sql='EXEC QPGameUserDB.dbo.Game_Web_GetUserPayOper 2,'+CAST(@UserID as varchar)+',0,0'
		Set @sql='SELECT * FROM OPENQUERY([QPGameUserDBLink],'''+@sql+''')'
		INSERT INTO @temp 
			exec (@sql)
		SET @RecvJD=0
		SET @RecvJB=0

		IF (SELECT count(1) FROM @temp WHERE [type] IN(1,2) AND subtype=@SubPayType)=0
		Begin
			IF @SubPayType=51804 --��Ҫ������6Ԫÿ�����
			BEGIN
				IF @fRmb=6
				BEGIN 
					SET @RecvJD=400
					SET @RecvJB=2000
				END
			END
			ELSE IF @SubPayType=10009 --��Ҫ������18Ԫÿ�����
			BEGIN
				IF @fRmb=18
				BEGIN 
					SET @RecvJD=1000
					SET @RecvJB=10000
				END
			end
			ELSE if @SubPayType=10010 --��Ҫ������58Ԫÿ�����
			BEGIN
				IF @fRmb=58
				BEGIN 
					SET @RecvJD=3000
					SET @RecvJB=30000
				END
			END
		END
		Set @vipType=0
		Set @vipDays=0
		Select @matchTicket=matchTicket FROM GQ_GamePay_ExtraGift_Config with(nolock) Where Rmb=@fRmb and PayType=4
	end
	else if @SubPayType=10006
	begin
		--��Ҫ�������׳������4Ԫ��200��+60��+10000��ң�
		declare @ispay int
		exec [QPGameUserDBLink].QPGameUserDB.dbo.Proc_UserOperationRecord_Select 1,@UserID,@ispay out
		if @fRmb=1 and @ispay=0
		begin
			set @RecvJD=70
			set @RecvJB=1000
		end
		Set @vipType=0
		Set @vipDays=0
		SET @matchTicket=0
	end
	else if @SubPayType=10008
	begin
		set @vipDays = 0
		set @vipType = 0
		set @RecvJD=0
		set @RecvJB=0
		SET @matchTicket=0
	end
	else if @SubPayType=10005--��Ҫ�������¿���ֵ
	begin
		SELECT @day=[days],@monthCardPrice=(case when isdiscount=1 then price*discount else price end) FROM T_MonthCardConfig WITH(NOLOCK) where rid=cast(@Remark as int)
		IF @monthCardPrice<>@fRmb
		Begin
			DECLARE @AfterPrice float
			SELECT top 1 @AfterPrice=AfterPrice FROM T_ReliveBargain_Details WITH(NOLOCK) WHERE IsDone=0 and InitiatorUserID=@UserID and GameID=2 and App=1 and RID=cast(@Remark as int) ORDER BY AddTime desc,AfterPrice asc
			--SELECT @AfterPrice
			IF @AfterPrice IS NULL
			BEGIN
				SET @Ret=-2 --����ȷ
				RETURN
			END
			ELSE
			BEGIN
				IF @AfterPrice<>@fRmb
				BEGIN
					SET @Ret=-2 --����ȷ
					RETURN
				END
			END
		End
		SET @RecvJB=@day
		SET @vipDays = 0
		SET @vipType = 0
		SET @matchTicket=0
	end
	else if @SubPayType = 10011 --91y��ͨ��ֵ
	begin
		Exec Game_Web_PayAsFishLevel @UserID,@RecvJB out,@PayType
	end
	else if @SubPayType>=100000 AND @SubPayType<200000 --�������Ʒ
	begin
		set @vipDays = 0
		set @vipType = 0
		set @RecvJD=0
		set @RecvJB=0
		SET @matchTicket=0
	END
	ELSE IF @SubPayType=200000 --91y�����׳����
	BEGIN
		SELECT [key],SUM(CAST([value] AS int)) AS [value] INTO #temp FROM T_SceneContent WITH(NOLOCK) WHERE sceneId=cast(@Remark as int) GROUP BY [key] 
		DECLARE @countnum INT
		SELECT @countnum=count(1) FROM #temp
		IF @countnum>0
		BEGIN
			SELECT @Price=ISNULL([value],0) FROM #temp WHERE [key]='RMB'
			IF @Price<>@fRmb
			BEGIN
				SET @Ret=-2 --����ȷ
				RETURN
			END 
			SELECT @RecvJB=ISNULL([value],0) FROM #temp WHERE [key]='JB'
			SELECT @vipDays=ISNULL([value],0) FROM #temp WHERE [key]='LZVIP'
			IF @vipDays>0
			BEGIN
				SET @vipType=2          
			END  
			ELSE
			BEGIN
				SELECT @vipDays=ISNULL([value],0) FROM #temp WHERE [key]='JZVIP'
				IF @vipDays>0
				BEGIN
					SET @vipType=3          
				END
			END
		END       
		
		SELECT @matchTicket=matchTicket FROM GQ_GamePay_ExtraGift_Config WITH(NOLOCK) WHERE Rmb=@fRmb and PayType=6 
		DROP TABLE #temp  
	END  

	if @RecvJB is null 
	begin
		set @Ret=-2 --����ȷ
		return
	end

	set @PDate=GETDATE()	
	if 	@SubPayType in (10004,51804,10006,10009,10010)
	begin
		Update dbo.GQ_GamePayLog
			Set @IntOrderID=id,
				@UserID=UserID,
				OrderOut=@sOrderOut,
				Rmb=@fRmb,
				RecvJB=@RecvJD,
				PDate=@PDate,
				Status=1,
				VipType=@vipType,
				VipDays=@vipDays,
				Param1=@Param1,
				Param2=@Param2
			Where OrderNum=@sOrderNum And Status=0
	end
	else 
	begin
		Update dbo.GQ_GamePayLog
			Set @IntOrderID=id,
				@UserID=UserID,
				OrderOut=@sOrderOut,
				Rmb=@fRmb,
				RecvJB=@RecvJB,
				PDate=@PDate,
				Status=1,
				VipType=@vipType,
				VipDays=@vipDays,
				Param1=@Param1,
				Param2=@Param2
			Where OrderNum=@sOrderNum And Status=0
	end
			
	if @@ROWCOUNT<=0
	Begin
		Set @Ret=-3 --�����Ѵ���򲻴���
		return
	End
	
	IF @SubPayType in(10004,51804,10006,10009,10010,10005)
	BEGIN
		EXEC QPGameUserDB.DBO.Proc_Pay_Useraccumulation @UserID,@PayType,2,@fRmb,NULL
	END
	ELSE
	BEGIN
		EXEC QPGameUserDB.DBO.Proc_Pay_Useraccumulation @UserID,@PayType,1,@fRmb,NULL
	END

	Insert Into GQ_GamePayLog_Complete(OrderId,AddDate)	Values(@IntOrderID,GETDATE())

	if @Remark in('618','600') and @fRmb >0 --��Ҫ�沶����ֲ���
	begin
		Exec QPGameUserDBLink.QPGameUserDB.dbo.Game_WEB_Share_AddIntegral 0,@UserID,@PayType,@fRmb,@sOrderNum,null
	end
	
	--�޸Ĺ���ȼ�
	Exec QPGameUserDBLink.QPGameUserDB.dbo.Game_Web_FishPayStatusApi @UserID,@fRmb,null

	If @vipType>0 and @vipDays>0
	Begin
		Exec QPGameUserDBLink.QPGameUserDB.dbo.PKManager_Accounts_EditVIP @UserID,@viptype,@vipDays,null
	End
	
	IF @matchTicket>0  --����Ʊ
	BEGIN 
		DECLARE @notes VARCHAR(100)
		SET @notes='��ֵ����Ʊ:'+cast(@UserID AS varchar(32))+',����:'+@sOrderNum+',��'+cast(@matchTicket AS varchar(32))+'����Ʊ'
		--QPTreasureDBLink
		EXEC [MatchDBLink].[fund].[dbo].[cpp_change_fund_match] 1,98,@UserID,94,@matchTicket,0,0,0,0,'',0,0,0,0,0,'',@notes
	END 

	Declare @Result int ,@Retmessage varchar(50),@CollectNote varchar(128),@CommuneID int
	if @SubPayType=10001 /*�����ֵ�߼�*/
	Begin
		SET @CollectNote ='��ֵ������ӱ�'+CAST(@RecvJB AS VARCHAR(32))
        Exec QPGameUserDBLink.QPGameUserDB.dbo.UnionSystem_CommuneScoreChange 1,6,NULL,@UserID,0,0,@RecvJB,0,0,@CollectNote,@sOrderNum,@PayType,@fRmb,NULL,@CommuneID out,@Result out,@Retmessage out

		if @Result=1
		Begin
			Exec QPGameUserDBLink.QPGameUserDB.dbo.UnionSystem_CommuneReceiveGoldOutTimes @CommuneID,@UserID,@fRmb,@sOrderNum,NULL

			Set @Ret=@RecvJB --��ֵ�ɹ�
			return
		End
		Else
		Begin
			Set @Ret=-4 --�ӹ�����ʧ��
			return
		End

	End
	else if @SubPayType=10002 --�����޹�
	begin
		If @RecvJB > 0
		Begin
			if @PropID=0 --�޹��ӱ�
			begin
				Exec QPGameUserDBLink.QPGameUserDB.dbo.Game_Web_PayStatusApi @UserID,1,@PayType,@fRmb, NULL,NULL	
				Exec QPTreasureDBLink.QPTreasureDB.dbo.GSP_Common_AccountScoreChange 1,10,@UserID,0,0,0,@RecvJB,0,0,'�����޹�',@sOrderNum,@PayType,@fRmb,null,null,@Result out,@Retmessage out	
				if @Result=1
				begin
					Set @Ret=@RecvJB --��ֵ�ɹ�
				end
				else
				begin
					Set @Ret=-4 --�ӱ�ʧ��
					return
				end
			end
		End
		else 
		begin
			Set @Ret=-4 --�ӽ��ʧ��
			return
		end 
		Update [dbo].[T_Activity_Panicbuying_Log] Set Status=1  Where ProductID=cast(@Remark as int) And UserID=@UserID and Status=0
	end
	Else If @SubPayType=10003 --91y�׳����
	Begin
		If @RecvJB > 0
		Begin
			if @PropID=2 --�׳�����ӱ�
			begin	
				Exec QPGameUserDBLink.QPGameUserDB.dbo.Game_Web_PayStatusApi @UserID,1,@PayType,@fRmb, NULL,NULL
				Exec QPTreasureDBLink.QPTreasureDB.dbo.GSP_Common_AccountScoreChange 1,10,@UserID,0,0,0,@RecvJB,0,0,'�׳����',@sOrderNum,@PayType,@fRmb,null,null,@Result out,@Retmessage out	
				if @Result=1
				begin
					Set @Ret=@RecvJB --��ֵ�ɹ�
					return
				end
				else
				begin
					Set @Ret=-4 --�ӱ�ʧ��
					return
				end
			end
		End
		else 
		begin
			Set @Ret=-4 --�ӽ��ʧ��
			return
		end 
	End
	else if @SubPayType in(10004,51804,10006,10009,10010) --�𶹳�ֵ
	begin
		Exec QPGameUserDBLink.QPGameUserDB.dbo.Game_Web_PayStatusApi @UserID,1,@PayType,@fRmb, NULL,NULL
		exec QPTreasureDBLink.QPTreasureDB.dbo.GSP_Common_AccountDiamondChange 1,70,@UserID,0,@RecvJD,0,0,0,0,0,'�𶹳�ֵ',@sOrderNum,@PayType,@fRmb,@SubPayType,null,null,null,@Result out,@Retmessage out
		if @SubPayType in (51804,10006,10009,10010)
		begin                                                                   --���������app��78
			Exec QPTreasureDBLink.QPTreasureDB.dbo.GSP_Common_AccountScoreChange 1,78,@UserID,0,0,0,@RecvJB,0,0,'ÿ�ճ�ֵ�Ż��ͽ��',@sOrderNum,@PayType,@fRmb,null,null,@Result out,@Retmessage out	
			if @SubPayType=51804 --ÿ������Ӹ��
			begin
				EXEC QPTreasureDBLink.Fund.dbo.cpp_relive_card_give_regpay @UserID,2
			end
			if @SubPayType=10010 --��ֵ58Ԫ���������
			begin
				DECLARE @change_time VARCHAR(32)
				SET @change_time = CONVERT(varchar(32),GETDATE(),121) 
				IF @UserID=35670125
				BEGIN
					IF @PDate>='2018-6-1' AND @PDate<'2018-6-20'
					BEGIN
						EXEC QPTreasureDBLink.Fund.dbo.cpp_change_fund_match 1, 0, @UserID, 347, 3, 10003, 0, 0, 0, '127.0.0.1', 10003, 13, 0, 0, 0, @change_time, '�����ֵ�'
					END
				END
				ELSE
				BEGIN
					IF @PDate>='2018-6-4' AND @PDate<'2018-6-20'
					BEGIN
						EXEC QPTreasureDBLink.Fund.dbo.cpp_change_fund_match 1, 0, @UserID, 347, 3, 10003, 0, 0, 0, '127.0.0.1', 10003, 13, 0, 0, 0, @change_time, '�����ֵ�'
					END
				END
			end
		end

		if @SubPayType in (51804,10009,10010)
		begin   
			exec QPGameUserDBLink.QPGameUserDB.dbo.Game_Web_UserPayOper 0,@UserID,1,@SubPayType
		end 
		
		if @Result=1
		begin
			Set @Ret=@RecvJD --��ֵ�ɹ�
			return
		end
		else
		begin
			Set @Ret=-4 --�ӱ�ʧ��
			return
		end
	end
	else if @SubPayType=10008 --��Ҫ�沶�㹺����̨
	begin
		declare @CannonId int, @Count_30 int

		Select top 1 @CannonId=VipType, @Count_30 = vipdays from [PKGameStat].[dbo].[GQ_GamePay_Config] where PayType = @SubPayType and Rmb = @subRmb

		if @CannonId is not null
		begin
			Exec @Ret = [QPTreasureDBLink].QPPropDB.dbo.GSP_PS_UserProp_AddOverDate @UserID,1,@CannonId,@Count_30,18,'��ֵ������̨'
		end
		return
	end
	else if @SubPayType=10005 --��Ҫ�������¿���ֵ
	begin
		declare @rid int,@ucount int
		set @rid=cast(@Remark as int)
		Exec QPGameUserDBLink.QPGameUserDB.dbo.Game_Web_PayStatusApi @UserID,1,@PayType,@fRmb, NULL,NULL
		SELECT @ucount=count(1) FROM T_ReliveBargain_Details WITH(NOLOCK) WHERE InitiatorUserID=@UserID and IsDone=0 and GameID=2 and App=1 and RID=@rid
		IF @ucount>0
		BEGIN
			SET @Result=0
			UPDATE T_ReliveBargain_Details set IsDone=1,DoneTime=getdate() where InitiatorUserID=@UserID and IsDone=0 and GameID=2 and App=1 and RID=@rid
			IF @@ROWCOUNT=@ucount
			BEGIN 
				Exec QPGameUserDBLink.QPGameUserDB.dbo.Game_Web_MatchUserMonthCardPay @UserID,@rid,@day,@PDate,@Result out
			END
		END
		ELSE
		BEGIN 
			Exec QPGameUserDBLink.QPGameUserDB.dbo.Game_Web_MatchUserMonthCardPay @UserID,@rid,@day,@PDate,@Result out
		END
		if @Result=1
		begin
			Set @Ret=@day --�ɹ�
			return
		end
		else
		begin
			Set @Ret=-4 --ʧ��
			return
		end
	END
	ELSE IF @SubPayType=200000 --91y�����׳����
	BEGIN
		DECLARE @LastPayPackageAmount INT, @tag INT=0
		EXEC [QPGameUserDBLink].QPGameUserDB.dbo.Proc_UserOperationRecord_Select 15,@UserID,@LastPayPackageAmount OUT
  PRINT @LastPayPackageAmount
  PRINT @fRmb  
		IF @LastPayPackageAmount=@fRmb
		BEGIN
			SET @RecvJB=@fRmb*10000
			SET @tag=1
		END  
		IF @RecvJB > 0
		BEGIN
			EXEC QPGameUserDBLink.QPGameUserDB.dbo.Game_Web_PayStatusApi @UserID,1,@PayType,@fRmb, NULL,NULL
			EXEC QPTreasureDBLink.QPTreasureDB.dbo.GSP_Common_AccountScoreChange 1,10,@UserID,0,0,0,@RecvJB,0,0,'�׳����',@sOrderNum,@PayType,@fRmb,null,null,@Result out,@Retmessage out	
			IF @Result=1
			BEGIN
   PRINT  @tag          
				IF @tag = 0
				BEGIN     
					EXEC QPGameUserDBLink.QPGameUserDB.dbo.Proc_UserOperationRecord_Action 10,@UserID,NULL,NULL,@fRmb, NULL 
				END 
				SET @Ret=@RecvJB --��ֵ�ɹ�
				RETURN
			END
			ELSE
			BEGIN
				SET @Ret=-4 --�ӱ�ʧ��
				RETURN
			END
		END 
		ELSE 
		BEGIN      
			SET @Ret=-4 --�ӽ��ʧ��
			RETURN 
		END  
	END  
	--else if @SubPayType>=100000 --�������Ʒ
	--BEGIN
	--	DECLARE @tempcom TABLE(GameId int,CommodityID int,CommodityName varchar(64),Rmb decimal(10,2),CommodityType int,IsPayNum int,[Status] int)
	--	INSERT INTO @tempcom EXEC [QPTreasureDB].[dbo].[Game_Web_GetCommodityConf] 0,@SubPayType
	--	IF(SELECT count(1) FROM @tempcom)>0
	--	BEGIN
	--		Exec QPGameUserDBLink.QPGameUserDB.dbo.Game_Web_PayStatusApi @UserID,1,@PayType,@fRmb, NULL,NULL

	--		DECLARE @CommodityType int,@IsPayNum int,@GameId int
	--		SELECT @CommodityType=CommodityType,@IsPayNum=IsPayNum,@GameId=GameId FROM @tempcom

	--		IF @GameId=2
	--		BEGIN
	--			IF @CommodityType=0 --ÿ�����
	--			BEGIN
	--				EXEC QPTreasureDBLink.QPTreasureDB.dbo.Proc_DDZ_CommodityConfPropAward @SubPayType,@UserID,2,@sOrderNum,@PayType,@fRmb,@Result out,@Retmessage out
	--				EXEC QPGameUserDBLink.QPGameUserDB.dbo.Game_Web_UserPayOper 0,@UserID,3,@SubPayType
	--			END
	--		END
	--		ELSE IF @GameId=0
	--		BEGIN
	--			IF @CommodityType=0 --ÿ�����
	--			BEGIN
	--				EXEC QPTreasureDBLink.QPTreasureDB.dbo.Proc_Lobby_CommodityConfPropAward @SubPayType,@UserID,0,@sOrderNum,@PayType,@fRmb,@Result out,@Retmessage out
	--				EXEC QPGameUserDBLink.QPGameUserDB.dbo.Game_Web_UserPayOper 0,@UserID,3,@SubPayType
	--			END
	--		END
	--		ELSE IF @GameId=618
	--		BEGIN
	--			Exec QPTreasureDBLink.QPTreasureDB.dbo.Commodity_PropAdd_ByCommodityType_Buyu @UserID,@SubPayType,@sOrderNum,@Result out, @Retmessage out
	--		END


	--		if @Result=1
	--		begin
	--			Set @Ret=1 --��ֵ�ɹ�
	--			return
	--		end
	--		else
	--		begin
	--			Set @Ret=-4 --�ӱ�ʧ��
	--			return
	--		end
	--end
	--END
	Else  /*�û���ֵ�߼�*/
	Begin
		--�¿���ֵ�򱣴��콱ʱ��2014-1-16zq
		begin try
			if @PayType in(1,2,8,17,29) and @fRmb in(29,99,299,199,1999)
			begin
				select top 1 @ReceiveTimeE=ReceiveTimeE from GQ_GamePay_ReceiveJBInfo with(nolock) where UserID=@UserID order by ReceiveTimeE desc 
				if @ReceiveTimeE is null
				begin
					set @ReceiveTimeE=@PDate 
				end
				if @PDate>=@ReceiveTimeE
				begin
					set @ReceiveTimeS=@PDate
				end
				else
				begin
					set @ReceiveTimeS=@ReceiveTimeE
				end
				--��ȡ30�죬������ֵ����
				set @ReceiveTimeE=CONVERT(char(10),DATEADD(DD,30,@ReceiveTimeS),121)
				insert into GQ_GamePay_ReceiveJBInfo(UserID,OrderNum,Rmb,PDate,ReceiveTimeS,ReceiveTimeE)
					values(@UserID,@sOrderNum,@fRmb,@PDate,@ReceiveTimeS,@ReceiveTimeE)
			end
		end try
		begin catch
		end catch
	
		Exec  QPGameUserDBLink.QPGameUserDB.dbo.Game_Web_PayStatusApi @UserID,1,@PayType,@fRmb, NULL,NULL



		Exec QPTreasureDBLink.QPTreasureDB.dbo.GSP_Common_AccountScoreChange 1,10,@UserID,0,0,0,@RecvJB,0,0,'��ֵ',@sOrderNum,@PayType,@fRmb,null,null,@Result out,@Retmessage out
	
		if @Result=1
		Begin
			--Update dbo.GQ_GamePayLog Set 	Status=1 Where OrderNum=@sOrderNum And Status=5

			Exec QPGameUserDBLink.QPGameUserDB.dbo.Game_Web_PaySendScore 0,@UserID,@RecvJB,NULL
			Set @Ret=@RecvJB --��ֵ�ɹ�
			return
		End
		Else
		Begin
			Set @Ret=-4 --�ӱ�ʧ��
			return
		End
	End
END



