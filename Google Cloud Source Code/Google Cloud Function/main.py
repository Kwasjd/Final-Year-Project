from flask import Flask, request
from google.api_core.client_options import ClientOptions
from google.cloud import documentai_v1

app = Flask(__name__)

#Project ID and Processor ID change accrodingly to what were created in your Google CLoud Platform

PROJECT_ID = "my-project4-377307" # Project ID change according to your Google Cloud Project ID
LOCATION = "us"  # Format is 'us' or 'eu'
PROCESSOR_ID = "d07bfe76b30a6e51"  # Create processor in Cloud Console (Change accordingly) 
LABELS = {
    "Energy": "Energy",
    "Energy_Per_100g": "Energy Per 100g",
    "Protein": "Protein",
    "Protein_Per_100g": "Protein Per 100g",
    "Total_Fat": "Total Fat",
    "Total_Fat_Per_100g": "Total Fat Per 100g",
    "Saturated_Fat": "Saturated Fat",
    "Saturated_Fat_Per_100g": "Saturated Fat Per 100g",
    "Trans_Fat": "Trans Fat",
    "Trans_Fat_Per_100g": "Trans Fat Per 100g",
    "Cholesterol": "Cholesterol",
    "Cholesterol_Per_100g": "Cholesterol Per 100g",
    "Carbohydrate": "Carbohydrate",
    "Carbohydrate_Per_100g": "Carbohydrate Per 100g",
    "Sugar": "Sugar",
    "Sugar_Per_100g": "Sugar Per 100g",
    "Dietary_Fibre": "Dietary Fibre",
    "Dietary_Fibre_Per_100g": "Dietary Fibre Per 100g",
    "Sodium": "Sodium",
    "Sodium_Per_100g": "Sodium Per 100g"    
}

# Define the desired order of the keys in the dictionary
KEY_ORDER = [
    "Energy",
    "Energy Per 100g",
    "Protein",
    "Protein Per 100g",
    "Total Fat",
    "Total Fat Per 100g",
    "Saturated Fat",
    "Saturated Fat Per 100g",
    "Trans Fat",
    "Trans Fat Per 100g",
    "Cholesterol",
    "Cholesterol Per 100g",
    "Carbohydrate",
    "Carbohydrate Per 100g",
    "Sugar",
    "Sugar Per 100g",
    "Dietary Fibre",
    "Dietary Fibre Per 100g",
    "Sodium",
    "Sodium Per 100g"
]

@app.route('/', methods=['POST'])
def process_image(req):
    # Check if the 'imagefile' key is in the request
    if 'imagefile' not in req.files:
        return 'No image file uploaded'

    # Get the image file from the request data
    imagefile = req.files['imagefile']

    # Check if the file object is not None
    if imagefile is None:
        return 'Invalid image file'

    # Load Binary Data into Document AI RawDocument Object
    MIME_TYPE = "image/jpeg"
    raw_document = documentai_v1.RawDocument(
        content=imagefile.read(), mime_type=MIME_TYPE)

    # Instantiates a client
    docai_client = documentai_v1.DocumentProcessorServiceClient(
        client_options=ClientOptions(
            api_endpoint=f"{LOCATION}-documentai.googleapis.com")
    )

    # The full resource name of the processor, e.g.:
    # projects/project-id/locations/location/processor/processor-id
    # You must create new processors in the Cloud Console first
    RESOURCE_NAME = docai_client.processor_path(
        PROJECT_ID, LOCATION, PROCESSOR_ID)

    # Configure the process request
    req = documentai_v1.ProcessRequest(
        name=RESOURCE_NAME, raw_document=raw_document)

    # Use the Document AI client to process the sample form
    result = docai_client.process_document(request=req)

    document_object = result.document

   # Define the labels of interest
    LABELS_OF_INTEREST = ['Energy', 'Protein', 'Total_Fat', 'Saturated_Fat', 'Trans_Fat', 'Cholesterol', 'Carbohydrate', 'Sugar', 'Dietary_Fibre', 'Sodium',  
                          'Energy_Per_100g', 'Protein_Per_100g', 'Total_Fat_Per_100g', 'Saturated_Fat_Per_100g', 'Trans_Fat_Per_100g', 'Cholesterol_Per_100g', 'Carbohydrate_Per_100g', 'Sugar_Per_100g', 'Dietary_Fibre_Per_100g', 'Sodium_Per_100g']

    # Extract entities
    entities = {}
    for entity in document_object.entities:
        mention_text = entity.mention_text.strip()
        label = entity.type
        if label in LABELS_OF_INTEREST:
            entities[LABELS[label]] = mention_text

    # Check if entities are detected
    if not entities:
        return 'No Nutrition Information Found'
    else:
        # Sort the dictionaries according to the KEY_ORDER
        sorted_dict = {k: entities[k] for k in KEY_ORDER if k in entities}

        # Define the entity variables
        energy = sorted_dict['Energy'].replace('*', '') if 'Energy' in sorted_dict else ''
        energy_per_100g = sorted_dict['Energy Per 100g'].replace('*', '') if 'Energy Per 100g' in sorted_dict else ''

        protein = sorted_dict['Protein'].replace('*', '') if 'Protein' in sorted_dict else ''
        protein_per_100g = sorted_dict['Protein Per 100g'].replace('*', '') if 'Protein Per 100g' in sorted_dict else ''

        total_fat = sorted_dict['Total Fat'].replace('*', '') if 'Total Fat' in sorted_dict else ''
        total_fat_per_100g = sorted_dict['Total Fat Per 100g'].replace('*', '') if 'Total Fat Per 100g' in sorted_dict else ''

        saturated_fat = sorted_dict['Saturated Fat'].replace('*', '') if 'Saturated Fat' in sorted_dict else ''
        saturated_fat_per_100g = sorted_dict['Saturated Fat Per 100g'].replace('*', '') if 'Saturated Fat Per 100g' in sorted_dict else ''

        trans_fat = sorted_dict['Trans Fat'].replace('*', '') if 'Trans Fat' in sorted_dict else ''
        trans_fat_per_100g = sorted_dict['Trans Fat Per 100g'].replace('*', '') if 'Trans Fat Per 100g' in sorted_dict else ''

        cholesterol = sorted_dict['Cholesterol'].replace('*', '') if 'Cholesterol' in sorted_dict else ''
        cholesterol_per_100g = sorted_dict['Cholesterol Per 100g'].replace('*', '') if 'Cholesterol Per 100g' in sorted_dict else ''

        carbohydrate = sorted_dict['Carbohydrate'].replace('*', '') if 'Carbohydrate' in sorted_dict else ''
        carbohydrate_per_100g = sorted_dict['Carbohydrate Per 100g'].replace('*', '') if 'Carbohydrate Per 100g' in sorted_dict else ''

        sugar = sorted_dict['Sugar'].replace('*', '') if 'Sugar' in sorted_dict else ''
        sugar_per_100g = sorted_dict['Sugar Per 100g'].replace('*', '') if 'Sugar Per 100g' in sorted_dict else ''

        dietary_fibre = sorted_dict['Dietary Fibre'].replace('*', '') if 'Dietary Fibre' in sorted_dict else ''
        dietary_fibre_per_100g = sorted_dict['Dietary Fibre Per 100g'].replace('*', '') if 'Dietary Fibre Per 100g' in sorted_dict else ''

        sodium = sorted_dict['Sodium'].replace('*', '') if 'Sodium' in sorted_dict else ''
        sodium_per_100g = sorted_dict['Sodium Per 100g'].replace('*', '') if 'Sodium Per 100g' in sorted_dict else ''
        

        # Combine the entity variables into a string
        entities_str = f"Energy {energy}\t\t {energy_per_100g}\nProtein {protein}\t\t {protein_per_100g}\nTotal Fat {total_fat}\t\t {total_fat_per_100g}\nSaturated Fat {saturated_fat}\t\t {saturated_fat_per_100g}\nTrans Fat {trans_fat}\t\t {trans_fat_per_100g}\nCholesterol {cholesterol}\t\t {cholesterol_per_100g}\nCarbohydrate {carbohydrate}\t\t {carbohydrate_per_100g}\nSugar {sugar}\t\t {sugar_per_100g}\nDietary Fibre {dietary_fibre}\t\t {dietary_fibre_per_100g}\nSodium {sodium}\t\t {sodium_per_100g}"
        
        return entities_str

if __name__ == "__main__":
    app.run()



