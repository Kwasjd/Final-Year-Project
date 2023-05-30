from google.api_core.client_options import ClientOptions
from google.cloud import documentai_v1 as documentai

# Change both "PROJECT_ID" and "PROCESSOR_ID" according to the project and 
# Document AI provided respectively 
PROJECT_ID = "my-project4-377307"
LOCATION = "us"  # Format is 'us' or 'eu'
PROCESSOR_ID = "d07bfe76b30a6e51"  # Create processor in Cloud Console

# The local file in your current working directory
FILE_PATH = "images/Baked Cheesy Pasta_20230323_010857_005.jpg"  #Change accordingly to where you saved your image in your local drive
# Refer to https://cloud.google.com/document-ai/docs/file-types
# for supported file types
MIME_TYPE = "image/jpeg"

# Instantiates a client
docai_client = documentai.DocumentProcessorServiceClient(
    client_options=ClientOptions(api_endpoint=f"{LOCATION}-documentai.googleapis.com")
)

# The full resource name of the processor, e.g.:
# projects/project-id/locations/location/processor/processor-id
# You must create new processors in the Cloud Console first
RESOURCE_NAME = docai_client.processor_path(PROJECT_ID, LOCATION, PROCESSOR_ID)

# Read the file into memory
with open(FILE_PATH, "rb") as image:
    image_content = image.read()

# Load Binary Data into Document AI RawDocument Object
raw_document = documentai.RawDocument(content=image_content, mime_type=MIME_TYPE)

# Configure the process request
request = documentai.ProcessRequest(name=RESOURCE_NAME, raw_document=raw_document)

# Use the Document AI client to process the sample form
result = docai_client.process_document(request=request)

document_object = result.document

# Extract entities
for entity in document_object.entities:
    print(f"Entity text: {entity.mention_text}\n")
    #print(f"Entity type: {entity.type}")
    try:
        confidence = entity.metadata.get(
            "entity_extraction", {}).get("confidence")
        print(f"Confidence score: {confidence}")
    except AttributeError:
        pass
