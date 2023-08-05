# Bring in deps
import os
import sys
import requests
import shutil
import prompts as pr

from apikey import apikey 
from langchain.llms import OpenAI
from langchain.prompts import PromptTemplate
from langchain.chains import LLMChain, SequentialChain 
from langchain.memory import ConversationBufferMemory

os.environ['OPENAI_API_KEY'] = apikey

# # Example usage:
source_folder = "./contracts"

document_folder = "./documents"
test_folder = "./test"
integration_folder = "./integration"

input = sys.argv[1]



doc_template = PromptTemplate(
    input_variables = ['topic'], 
    template=pr.createDocument
)

test_template = PromptTemplate(
    input_variables = ['topic'], 
    template=pr.createTest
)

integration_template = PromptTemplate(
    input_variables = ['topic'], 
    template=pr.createIntegration
)

# # Llms
llm = OpenAI(temperature=0.9,model_name="gpt-3.5-turbo") 
doc_chain = LLMChain(llm=llm, prompt=doc_template, verbose=True, output_key='title')
test_chain = LLMChain(llm=llm, prompt=test_template, verbose=True, output_key='title')
integration_chain = LLMChain(llm=llm, prompt=integration_template, verbose=True, output_key='title')


def createDoc(source_folder, destination_folder):
    # Create the destination folder if it doesn't exist
    if not os.path.exists(destination_folder):
        os.makedirs(destination_folder)

    # Fetch all .sol files from the source folder
    sol_files = [file for file in os.listdir(source_folder) if file.endswith('.sol')]
    
    # Iterate over each file and copy it to the destination folder
    for source_file in sol_files:

        # Get the full path of the source file
        source_file_path = os.path.join(source_folder, source_file)

        # Read the file data
        with open(source_file_path, 'r') as _source_file:
            file_data = _source_file.read()

        print(file_data)
        # Create the destination file name with .txt extension
        destination_file_name = f"{os.path.splitext(source_file)[0]}.txt"

        # Get the full path of the destination file
        destination_file_path = os.path.join(destination_folder, destination_file_name)

        doc = doc_chain.run(file_data)

        # Write the file data to the destination file
        with open(destination_file_path, 'w') as destination_file:
            destination_file.write(doc)

    print("document created successfully.")



def createTest(source_folder, destination_folder):
    # Create the destination folder if it doesn't exist
    if not os.path.exists(destination_folder):
        os.makedirs(destination_folder)

    # Fetch all .sol files from the source folder
    sol_files = [file for file in os.listdir(source_folder) if file.endswith('.sol')]
    
    # Iterate over each file and copy it to the destination folder
    for source_file in sol_files:

        # Get the full path of the source file
        source_file_path = os.path.join(source_folder, source_file)

        # Read the file data
        with open(source_file_path, 'r') as _source_file:
            file_data = _source_file.read()

        # Create the destination file name with .txt extension
        destination_file_name = f"{os.path.splitext(source_file)[0]}.ts"

        # Get the full path of the destination file
        destination_file_path = os.path.join(destination_folder, destination_file_name)

        doc = test_chain.run(file_data)

        # Write the file data to the destination file
        with open(destination_file_path, 'w') as destination_file:
            destination_file.write(doc)
    
    print("test created successfully.")


def createIntegration(source_folder, destination_folder):
    # Create the destination folder if it doesn't exist
    if not os.path.exists(destination_folder):
        os.makedirs(destination_folder)

    # Fetch all .sol files from the source folder
    sol_files = [file for file in os.listdir(source_folder) if file.endswith('.sol')]
    
    # Iterate over each file and copy it to the destination folder
    for source_file in sol_files:

        # Get the full path of the source file
        source_file_path = os.path.join(source_folder, source_file)

        # Read the file data
        with open(source_file_path, 'r') as _source_file:
            file_data = _source_file.read()

        # Create the destination file name with .txt extension
        destination_file_name = f"{os.path.splitext(source_file)[0]}.ts"

        # Get the full path of the destination file
        destination_file_path = os.path.join(destination_folder, destination_file_name)

        doc = integration_chain.run(file_data)

        # Write the file data to the destination file
        with open(destination_file_path, 'w') as destination_file:
            destination_file.write(doc)
    
    print("Integration file created successfully.")


def execute(option):
    if option == "document":
        createDoc(source_folder, document_folder);
    elif option == "test":
        createTest(source_folder, test_folder);
    elif option == "integration":
        createIntegration(source_folder, integration_folder);
    else:
        print("Invalid option. Please choose 'test' or 'document' or 'integration'.")


execute(input);

####################################################################################

# os.environ['OPENAI_API_KEY'] = apikey

# # App framework
# st.title('🦜🔗 YouTube GPT Creator')
# prompt = st.text_input('Plug in your prompt here') 

# # Prompt templates
# title_template = PromptTemplate(
#     input_variables = ['topic'], 
#     template='write me a youtube video title about {topic}'
# )

# script_template = PromptTemplate(
#     input_variables = ['title', 'wikipedia_research'], 
#     template='write me a youtube video script based on this title TITLE: {title} while leveraging this wikipedia reserch:{wikipedia_research} '
# )

# # Memory 
# title_memory = ConversationBufferMemory(input_key='topic', memory_key='chat_history')
# script_memory = ConversationBufferMemory(input_key='title', memory_key='chat_history')


# # Llms
# llm = OpenAI(temperature=0.9,model_name="gpt-3.5-turbo") 
# title_chain = LLMChain(llm=llm, prompt=title_template, verbose=True, output_key='title', memory=title_memory)
# script_chain = LLMChain(llm=llm, prompt=script_template, verbose=True, output_key='script', memory=script_memory)

# wiki = WikipediaAPIWrapper()

# # Show stuff to the screen if there's a prompt
# if prompt: 
#     title = title_chain.run(prompt)
#     wiki_research = wiki.run(prompt) 
#     script = script_chain.run(title=title, wikipedia_research=wiki_research)

#     st.write(title) 
#     st.write(script) 

#     with st.expander('Title History'): 
#         st.info(title_memory.buffer)

#     with st.expander('Script History'): 
#         st.info(script_memory.buffer)

#     with st.expander('Wikipedia Research'): 
#         st.info(wiki_research)