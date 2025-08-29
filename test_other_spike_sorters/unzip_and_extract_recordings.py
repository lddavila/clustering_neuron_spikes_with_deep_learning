from extract_recordings import extract_recordings
import zipfile
import os
def unzip_and_extract_recordings(list_of_zipped_files):
    for zip_file_path in list_of_zipped_files:
        head, destination_directory = os.path.split(zip_file_path)
        destination_directory = os.path.join(head, os.path.splitext(os.path.basename(zip_file_path))[0])
        # Create destination directory if it doesn't exist
        os.makedirs(destination_directory, exist_ok=True)
        # Unzip the file
        try:
            with zipfile.ZipFile(zip_file_path, 'r') as zip_ref:zip_ref.extractall(destination_directory)
            print(f"Successfully extracted '{zip_file_path}' to '{destination_directory}'")
        except zipfile.BadZipFile:
            print(f"Error: '{zip_file_path}' is not a valid ZIP file.")
        except FileNotFoundError:
            print(f"Error: ZIP file not found at '{zip_file_path}'.")
        except Exception as e:
            print(f"An unexpected error occurred: {e}")
        extract_recordings(destination_directory)