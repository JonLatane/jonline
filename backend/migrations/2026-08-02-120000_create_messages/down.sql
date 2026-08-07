DROP TABLE message_recipients;
DROP TYPE recipient_type;
DROP TRIGGER IF EXISTS messages_search_text_update ON messages;
DROP FUNCTION IF EXISTS messages_search_text_trigger();
DROP FUNCTION IF EXISTS messages_build_search_text(VARCHAR, TEXT, JSONB);
DROP TABLE messages;
