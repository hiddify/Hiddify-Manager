import os
import sys
import platform
import hashlib
import urllib.request
import zipfile
import tarfile
from packaging import version
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import PACKAGES_LOCK

def get_arch():
    arch = platform.machine().lower()
    if arch in ['x86_64', 'amd64']:
        return 'amd64'
    elif arch in ['aarch64', 'arm64']:
        return 'arm64'
    return arch

def calculate_hash(file_path):
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def get_latest_package_info(package_name):
    packages_lock_path = PACKAGES_LOCK
    arch = get_arch()
    
    latest_ver = None
    latest_info = None
    
    if not os.path.exists(packages_lock_path):
        log.error(f"packages.lock not found at {packages_lock_path}")
        return None
        
    with open(packages_lock_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split('|')
            if len(parts) == 5:
                p_name, p_version, p_arch, p_url, p_hash = parts
                if p_name == package_name and p_arch == arch:
                    try:
                        v = version.parse(p_version)
                        if latest_ver is None or v > latest_ver:
                            latest_ver = v
                            latest_info = {
                                "name": p_name,
                                "version": p_version,
                                "arch": p_arch,
                                "url": p_url,
                                "hash": p_hash
                            }
                    except Exception:
                        pass
    return latest_info

def download_package(package_name, output_file):
    info = get_latest_package_info(package_name)
    if not info:
        log.error(f"Package info not found for {package_name}")
        return False
        
    log.info(f"Downloading {package_name} version {info['version']} for {info['arch']}...")
    try:
        urllib.request.urlretrieve(info['url'], output_file)
        
        file_hash = calculate_hash(output_file)
        if file_hash != info['hash']:
            log.error(f"Hash mismatch for {package_name}. Expected {info['hash']}, got {file_hash}")
            os.remove(output_file)
            return False
            
        log.info(f"Successfully downloaded {package_name} and verified hash.")
        return True
    except Exception as e:
        log.error(f"Failed to download {package_name}: {e}")
        return False

def extract_package(file_path, extract_dir):
    try:
        if file_path.endswith('.zip'):
            with zipfile.ZipFile(file_path, 'r') as zip_ref:
                zip_ref.extractall(extract_dir)
            return True
        elif file_path.endswith('.tar.gz') or file_path.endswith('.tgz'):
            with tarfile.open(file_path, 'r:gz') as tar_ref:
                tar_ref.extractall(extract_dir)
            return True
        else:
            log.error(f"Unsupported extraction format for {file_path}")
            return False
    except Exception as e:
        log.error(f"Failed to extract {file_path}: {e}")
        return False
