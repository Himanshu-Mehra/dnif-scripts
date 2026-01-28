from cryptography.fernet import Fernet

# Generate once and store safely
# print(Fernet.generate_key())

KEY = b'J91U7ESdEGr39Md5FEtaDcQ6thucTiRdTyAT_Hp5sQk='
fernet = Fernet(KEY)

def encrypt_password(password):
    return fernet.encrypt(password.encode()).decode()

def decrypt_password(enc_password):
    return fernet.decrypt(enc_password.encode()).decode()