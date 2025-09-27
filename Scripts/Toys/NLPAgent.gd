# TODO: have your server use Turtle or a similar audio library to provide text-to-audio! 
# you can basically do audio-books this way.

extends Node

var intents = {
	"greeting": ["hello", "hi", "hey"],
	"farewell": ["bye", "goodbye", "see you"],
}

func recognize_intent(user_input: String) -> String:
	var lower_input = user_input.to_lower()

	for intent in intents.keys():
		var keywords = intents[intent]
		for keyword in keywords:
			if lower_input.find(keyword) != -1:
				return intent

	# If no intent is recognized, add a new one based on user input
	var new_intent = lower_input.replace(" ", "_")
	intents[new_intent] = [lower_input]
	return new_intent

# Example of using the intent recognizer
func _ready():
	var user_input = "Hello, how are you?"
	var recognized_intent = recognize_intent(user_input)
	
	print("User Input:", user_input)
	print("Recognized Intent:", recognized_intent)
	print("Updated Intents:", intents)




# uses Natural Language Processing (NLP) technology to create a chat agent

func tokenize(input_string: String) -> Array:
	var tokens = []
	
	# Split the input string into words
	var words = input_string.split(" ")

	# Process each word and add to tokens
	for word in words:
		# Remove leading and trailing whitespace
		var cleaned_word = word.strip_edges()

		# Check if the cleaned word is not empty
		if cleaned_word != "":
			tokens.append(cleaned_word)

	return tokens

## Example of using the tokenizer
#func _ready():
#	var input_text = "This is a sample sentence for tokenization."
#	var tokenized_result = tokenize(input_text)
#
#	print("Input Text:", input_text)
#	print("Tokenized Result:", tokenized_result)
