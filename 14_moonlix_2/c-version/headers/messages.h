// Команда приложению на то, чтобы обновить окно
#define MSG_UPDATE_WINDOW     1

// Если присутствует этот бит, то все нижние 0..8 биты - это ascii-код от клавиатуры
#define MSG_MESSAGE           0x200 

// Типы данных от сообщения
#define MSG_HWND              1 // Получение HWND от сообщения
#define MSG_ACTION            2 // get message action