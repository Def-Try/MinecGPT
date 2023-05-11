local component = require("component")
local internet = require("internet")
local json = require("json")
local event = require("event")
local chat = component.chat

local name = "ChatGPT" -- имя чатбокса в чате
local key = "КЛЮЧ OpenAI СЮДА" -- ваш ключ для доступа к API
local model = "gpt-3.5-turbo" -- Модель. если у вас есть доступ к gpt-4 api, можете поставить сюда что то другое
local max_tokens = 1024 -- кол-во токенов на один ответ. может быть меньше

chat.setName(name)
local function genresponse(messages)
  local data = '{"messages": ['..json:encode(messages):sub(2,-2)..'], "max_tokens": '..max_tokens..', "model": "'..model..'"}'
  local handle = internet.request("https://api.openai.com/v1/chat/completions", data, {
    ["Content-Type"] = "application/json", ["Authorization"] = "Bearer "..key, ["User-Agent"] = "curl/1.1.1", ["Accept"] = "*/*", ["Content-Length"] = #data
  }, "POST")
  local r = ""
  for i in handle do r = r .. i end
  return r
end
local messages = {}

messages[1] = {["role"] = "user", ["content"] = "Говори на русском. Ты запущен на компьютере, в майнкрафте. Ты будешь видеть сообщения игроков в формате '[внутриигровые_дата_и_время] имя_игрока: сообщение' - например '[Wed Dec 09 23:48:09] CasualName: Привет. как дела?'. Отвечать ты должен как обычно, не как игрок - например 'Привет. CasualName. У меня всё нормально.'. Тебя зовут "..name}
while true do
  local event_data = {event.pull()}
  if event_data[1] == "interrupted" then break end
  if event_data[1] == "chat_message" then
    local words = {}
    for w in string.gmatch(event_data[4], "[^%s]*") do table.insert(words, w) end
    if words[1]:lower() == "!gpt" or words[1]:lower() == "!гпт" then
      table.insert(messages, {["role"] = "user", ["content"] = "["..os.date("%c").."] "..event_data[3]..": "..event_data[4]:sub(#words[1]+2)})
      print("> "..messages[#messages].content)
      local r = genresponse(messages)
      r = json:decode(r)
      chat.say(r.choices[1].message.content)
      table.insert(messages, r.choices[1].message)
      print("< ["..os.date("%c").."] "..name..": "..r.choices[1].message.content)
    end
  end
end