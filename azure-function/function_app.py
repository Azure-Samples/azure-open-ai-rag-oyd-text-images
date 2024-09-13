import logging
import azure.functions as func
import json
import sys
import io
import os
import fitz  # PyMuPDF
from azure.storage.blob import BlobServiceClient
from azure.identity import DefaultAzureCredential

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

BLOB_CONTAINER_NAME = os.environ.get('BLOB_CONTAINER_NAME', 'data')
BLOB_TEXT_DIR_FILE_PREFIX = os.environ.get('BLOB_TEXT_DIR_FILE_PREFIX', 'prepaired_data/text')
BLOB_IMAGES_DIR_FILE_PREFIX = os.environ.get('BLOB_TEXT_DIR_FILE_PREFIX', 'prepaired_data/image')
PAGE_TEXT_CHUNK_WORD_SIZE = int(os.environ.get('PAGE_TEXT_CHUNK_WORD_SIZE', 200)) # 200 represent count of words, not characters.
MIN_IMAGE_SIZE = os.environ.get('MIN_IMAGE_SIZE', 2048) # Filter out images that are less than in size.
MIN_VECTOR_GRAPHIC_SIZE = os.environ.get('MIN_VECTOR_GRAPHIC_SIZE', 2048) # Filter out vector graphics that are less than in size.
EXTRACT_VECTOR_GRAPHICS = os.environ.get('EXTRACT_VECTOR_GRAPHICS', 'false') # Should vector graphics be extracted. Valid values true/false.

config = {
    'container_name': BLOB_CONTAINER_NAME,
    'text_dir_prefix': BLOB_TEXT_DIR_FILE_PREFIX,
    'image_dir_prefix': BLOB_IMAGES_DIR_FILE_PREFIX,
    'chunk_size': PAGE_TEXT_CHUNK_WORD_SIZE,
    'min_img_size': MIN_IMAGE_SIZE,
    'min_vector_graphic_size': MIN_VECTOR_GRAPHIC_SIZE,
    'extract_vector_graphics': EXTRACT_VECTOR_GRAPHICS
}

class ImgExtractor:
    
    @staticmethod
    def run_extractor(url, config):
        blob, container, filepath, filename = ImgExtractor.parse_blob_url(url)
        filename_without_extention = filename.split('.')[0].replace(' ', '-')
        client = ImgExtractor.get_client(blob)
        stream = ImgExtractor.download_blob_to_stream(client, container, filepath)
        ImgExtractor.extract_and_upload(client, blob, filename_without_extention, stream, config)

    @staticmethod
    def parse_blob_url(url):
        # Not the best way of doing it, but it works.
        blob = f"{url.split('.net')[0]}.net"
        container = url.split('.net/')[1].split('/')[0]
        filepath = '/'.join(url.split('.net/')[1].split('/')[1:])
        filename = url.split('/')[-1]
        
        return blob, container, filepath, filename

    @staticmethod
    def download_blob_to_stream(blob_service_client: BlobServiceClient, container_name, filpath):
        print('>>> downloading file from blob')
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=filpath)
        stream = io.BytesIO()
        num_bytes = blob_client.download_blob().readinto(stream)
        print(f"Number of bytes: {num_bytes}")
        print('<<< downloading file from blob')
        return stream

    @staticmethod
    def upload_blob_file(blob_service_client: BlobServiceClient, container_name: str, file_name, data, overwrite=True):
        print('>>> uploading file from blob')
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=file_name)
        # data = b"Sample data for blob"

        # Upload the blob data - default blob type is BlockBlob
        blob_client.upload_blob(data, blob_type="BlockBlob", overwrite=overwrite)
        print('<<< uploading file from blob')

    @staticmethod
    def get_client(account_url):
        credential = DefaultAzureCredential()
        service = BlobServiceClient(account_url=account_url, credential=credential)

        return service
    
    @staticmethod
    def chunk_page(strl, length):
        return (' '.join(strl[i:length + i]) for i in range(0, len(strl), length))

    @staticmethod
    def extract_and_upload(service, blob, filename_without_extention, pdf_stream, config):        
        dest_container_name = config['container_name']
        chunk_size = config['chunk_size']
        text_dir_prefix = config['text_dir_prefix']
        image_dir_prefix = config['image_dir_prefix']
        min_img_size = config['min_img_size']
        min_vector_graphic_size = config['min_vector_graphic_size']
        extract_vector_graphics = config['extract_vector_graphics']
        
        print('>>> extracting images from file')
        # Open the PDF file
        pdf = fitz.open(stream=pdf_stream)
        data_list = []
        
        # Iterate over PDF pages
        for page_num in range(len(pdf)):
            page = pdf[page_num]
            
            image_url = []
            
            def get_vector_graphics():
                # extract vector graphic objects
                bboxes = page.cluster_drawings()

                # Iterate through each bounding box
                for i, bbox in enumerate(bboxes):
                    # Get the pixmap for the bounding box
                    pix = page.get_pixmap(clip=bbox)
                    
                    # Save the pixmap as an image
                    filename = f"sample-{page_num + 1}-{i + 1}.png"
                    pix.save(filename)
                    pix
                    print(f"Saved {filename}")
            
            # Extract images
            for img_num, img in enumerate(page.get_images(full=True)):
                xref = img[0]
                base_image = pdf.extract_image(xref)
                image_bytes = base_image["image"]
                
                file_name = f"image_{page_num + 1}_{img_num + 1 }.png"
                full_file_path = f'{image_dir_prefix}/{filename_without_extention}/{file_name}'
                
                # Filter out very small images that are likely an empty image or a small icon.
                if sys.getsizeof(image_bytes) > min_img_size:
                    image_url.append(f'{blob}/{dest_container_name}/{full_file_path}')
                    print(f'>>> uploading image: {file_name}')
                    ImgExtractor.upload_blob_file(service, dest_container_name, full_file_path, image_bytes)
                    
            if extract_vector_graphics == 'true':
                drawings = page.cluster_drawings()

                for vg_num, drawing in enumerate(drawings):
                    file_name = f"image_vg_{page_num + 1}_{vg_num + 1 }.png"
                    full_file_path = f'{image_dir_prefix}/{filename_without_extention}/{file_name}'
                    pix = page.get_pixmap(clip=drawing)
                    image_bytes = pix.tobytes()

                    # Filter out very small vetor draving that are likely an empty image or a small icon.
                    if sys.getsizeof(image_bytes) > min_vector_graphic_size:
                        image_url.append(f'{blob}/{dest_container_name}/{full_file_path}')
                        print(f'>>> uploading image: {file_name}')
                        ImgExtractor.upload_blob_file(service, dest_container_name, full_file_path, image_bytes)

            page_text = page.get_text()
            word_list = page_text.split(' ')
            for chunk in ImgExtractor.chunk_page(word_list, chunk_size):
                data_list.append({'content': {'chunk': chunk, 'imgurl': image_url}})
        
        print(f'>>> uploading text: {file_name}')
        full_file_path = f'{text_dir_prefix}/{filename_without_extention}.json'
        
        # Upload content and metadata
        ImgExtractor.upload_blob_file(service, dest_container_name, full_file_path, json.dumps(data_list))

        # Close the PDF after extraction
        pdf.close()
        print('<<< extracting images from file')


# Can be used to test from local machine without deployment to Azure Fuction.
# Have to be deployed to test from the event trigger (aka end-to-end flow).
def test():
    urls = [
        # 'https://BLOB-NAME.blob.core.windows.net/data/raw_data/FILE-NAME.pdf',
    ]
    
    for url in urls:
        ImgExtractor.run_extractor(url, config)


@app.blob_trigger(arg_name="req", path="data/raw_data/{name}.pdf", connection="BLON_STORAGE_CONNECTION") 
def split_pdf(req: func.InputStream):
    logging.info('Python HttpRequest trigger function processing the event.')
    logging.info(req.uri)
    ImgExtractor.run_extractor(req.uri, config)
