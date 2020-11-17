﻿&НаКлиенте
Процедура ЗагрузитьИзExcel(Команда)
	
	ДиалогВыбора = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Открытие);
	ДиалогВыбора.Заголовок = "Выберите файл";
	
	Если ДиалогВыбора.Выбрать() Тогда
		
		ИмяФайлаЭксель = ДиалогВыбора.ПолноеИмяФайла;
	КонецЕсли;
	
	ЗАПОЛНИТЬВСЕ(); 
КонецПроцедуры

&НаСервере
Процедура ЗАПОЛНИТЬВСЕ()
	НомерПервойСтроки = 1;
	НомерПервойКолонки = 1;
	КоличествоСтрокВЭксель = 0;
	КоличествоКолонокВЭксель = 0;
	
	
	Попытка
		Эксель = Новый COMObject("Excel.Application");

		 Книга = Эксель.WorkBooks.Open(ИмяФайлаЭксель);
		//Состояние("Обработка файла Microsoft Excel...");
	Исключение
		Сообщить("Ошибка при открытии файла с помощью Excel! Загрузка не будет произведена!");
		Сообщить(ОписаниеОшибки());
		Возврат;
	КонецПопытки;
	
	Попытка 
		Листы=Книга.Worksheets;
		Лист=Листы.Item(1);
		Диапазон=Лист.UsedRange;
		//Эксель.Sheets(1).Select();    
	Исключение
		//Закрываем Excel
		Эксель.ActiveWorkbook.Close();  
		Эксель = 0;
		Сообщить("Файл "+Строка(ИмяФайлаЭксель)+" не соответствует необходимому формату! Первый лист не найден!");
		Возврат;
	КонецПопытки;
	
	//Получим количество строк и колонок.
	КоличествоСтрокВЭксель = Эксель.Cells.SpecialCells(11).Row - 20;
	КоличествоКолонокВЭксель = Эксель.Cells.SpecialCells(11).Column;
	Поиск=Диапазон.Find("Товар", Эксель.Cells(1, 1), -4123, 1, 1, 1, 0, 0);
	НачО = Сред(Поиск.Address,4);
	НачалоОтсчета = Число(НачО) +3;
	Поиск=Диапазон.Find("Итого", Эксель.Cells(1, 1), -4123, 1, 1, 1, 0, 0);
	КонО = Сред(Поиск.Address,4);
	КонецОтсчета = Число(КонО) - 1;
	
	//создаешь документ установки цен номенкл
	НовыйДокумент = Документы.УстановкаЦенНоменклатуры.СоздатьДокумент();
	НовыйДокумент.Дата =  ТекущаяДата();
	
	
	Для Сч = НачалоОтсчета по КонецОтсчета Цикл
		
		Наименование =	Эксель.Cells(Сч, 2).Value;		
		Артикул =	Эксель.Cells(Сч, 3).Value;		
		Код =	Эксель.Cells(Сч, 5).Value;
		Цена =	Эксель.Cells(Сч, 11).Value;	
		Номенкл = ПолучитьНоменклатуру(Наименование, Артикул,Код);
		СтрокаТЧ = НовыйДокумент.Товары.Добавить();
		СтрокаТЧ.Номенклатура= Номенкл;
		СтрокаТЧ.Цена = Цена;
		СтрокаТЧ.ВидЦены = СылкаВидыЦен;
		СтрокаТЧ = НовыйДокумент.ВидыЦен.Добавить();
		СтрокаТЧ.ВидЦены = СылкаВидыЦен;



		
	КонецЦикла;
	Попытка
		Эксель.DisplayAlerts = 0;
		Эксель.ActiveWorkbook.Close();
		Эксель.DisplayAlerts = 1;
		Эксель.Quit();                            
		Эксель = Неопределено;        
	Исключение
		Сообщить("Не удалось отключиться от Excel - " + ОписаниеОшибки());
		Возврат;
	КонецПопытки;
	
	    НовыйДокумент.Записать()
		
КонецПроцедуры

&НаСервере
Функция ПолучитьНоменклатуру(Наименование,Артикул,Код)
	
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
	|	Номенклатура.Наименование КАК Наименование,
	|	Номенклатура.Ссылка КАК Ссылка
	|ИЗ
	|	Справочник.Номенклатура КАК Номенклатура
	|ГДЕ
	|	Номенклатура.Наименование = &Наименование
	|	И Номенклатура.Артикул = &Артикул" ;
	Запрос.УстановитьПараметр("Наименование", Наименование);
	Запрос.УстановитьПараметр("Артикул", Артикул);
	
	РезультатЗапроса = Запрос.Выполнить().Выгрузить();
	
	Если РезультатЗапроса.Количество()> 0 Тогда 
		
		Сообщить("Товар уже добавлен в базу");
		ПолученнаяНоменклатура = РезультатЗапроса[0];
		
	Иначе
		
		ПолученнаяНоменклатура = Справочники.Номенклатура.СоздатьЭлемент();
		
		ПолученнаяНоменклатура.Наименование  = Наименование ;
		//заполнить ед измерения из справочника упаковки упаковки и ед изм
		ПолученнаяНоменклатура.Артикул = СокрП(Артикул);
		ПолученнаяНоменклатура.Записать();
		Сообщить("Записан"+ ПолученнаяНоменклатура.Наименование ); 
		
	КонецЕсли;
	Возврат ПолученнаяНоменклатура.Ссылка;
	
	ЗапросЕд = Новый Запрос;
	ЗапросЕд.Текст = "ВЫБРАТЬ
	|	УпаковкиЕдиницыИзмерения.Код КАК Код,
	|	УпаковкиЕдиницыИзмерения.Ссылка КАК Ссылка
	|ИЗ
	|	Справочник.УпаковкиЕдиницыИзмерения КАК УпаковкиЕдиницыИзмерения
	|ГДЕ
	|	УпаковкиЕдиницыИзмерения.Код = &Код" ;
	
	ЗапросЕд.УстановитьПараметр("Код", Строка(Код));
	
	РезультатЗапросаЕд = ЗапросЕд.Выполнить().Выгрузить();
	
	Если РезультатЗапросаЕд.Количество()> 0 Тогда 
		
		Сообщить("Единица уже добавлена в базу");
		ПолученныеЗначения = РезультатЗапросаЕд[0].Ссылка;
	Иначе
		
		ПолученныеЗначения = Справочники.УпаковкиЕдиницыИзмерения.СоздатьЭлемент();
		
		//заполнить ед измерения из справочника упаковки упаковки и ед изм
		ПолученныеЗначения.Код = Код;
		ПолученныеЗначения.Записать();
		Сообщить("Записан"+ ПолученныеЗначения.Код ); 
		
	КонецЕсли;
	КонецФункции

