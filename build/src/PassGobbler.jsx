import React, { useState, useMemo, useEffect } from "react";
import {
  Search,
  Copy,
  Eye,
  EyeOff,
  Trash2,
  Plus,
  Check,
  X,
  RefreshCw,
} from "lucide-react";
import logo from "./logo.png";
import CryptoJS from 'crypto-js';
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand, PutCommand, DeleteCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({
  region: "us-east-1", // e.g., 'us-west-2' // use variable pls
  credentials: {
    accessKeyId: import.meta.env.VITE_AWS_ACCESS_KEY_ID, // change later to use backend instead of this 
    secretAccessKey: import.meta.env.VITE_AWS_SECRET_ACCESS_KEY// change later to use backend instead of this
  }
});

const docClient = DynamoDBDocumentClient.from(client);

// Encryption key (in a real-world scenario, this should be securely managed)
const ENCRYPTION_KEY = import.meta.env.ENCRYPTION_KEY; // change later to use backend instead of this

const encryptPassword = (password) => {
  return CryptoJS.AES.encrypt(password, ENCRYPTION_KEY).toString();
};

const decryptPassword = (encryptedPassword) => {
  const bytes = CryptoJS.AES.decrypt(encryptedPassword, ENCRYPTION_KEY);
  return bytes.toString(CryptoJS.enc.Utf8);
};

const FloatingSymbol = React.memo(({ symbol, style }) => (
  <div
    className="absolute text-indigo-300 select-none pointer-events-none"
    style={{
      ...style,
      animation: `float ${style.duration}s linear infinite`,
    }}
  >
    {symbol}
  </div>
));

const BackgroundAnimation = React.memo(() => {
  const symbols = ["*", "#", "@", "&", "%", "$", "!", "?", "~", "(～￣▽￣)"];

  const floatingSymbols = useMemo(() => {
    return symbols.flatMap((symbol) =>
      Array(3)
        .fill()
        .map((_, index) => ({
          id: `${symbol}-${index}`,
          symbol,
          style: {
            left: `${Math.random() * 100}vw`,
            top: `${Math.random() * 100}vh`,
            fontSize: `${Math.random() * 20 + 10}px`,
            duration: Math.random() * 10 + 20,
          },
        })),
    );
  }, []);

  return (
    <div className="fixed inset-0 overflow-hidden pointer-events-none">
      {floatingSymbols.map(({ id, symbol, style }) => (
        <FloatingSymbol key={id} symbol={symbol} style={style} />
      ))}
    </div>
  );
});

const PassGobbler = () => {
  const [passwords, setPasswords] = useState([]);
  const [newSite, setNewSite] = useState("");
  const [newUsername, setNewUsername] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [showPassword, setShowPassword] = useState({});
  const [searchTerm, setSearchTerm] = useState("");
  const [copiedStates, setCopiedStates] = useState({});
  const [deleteConfirmation, setDeleteConfirmation] = useState({});

  useEffect(() => {
    fetchPasswords();
  }, []);

  const fetchPasswords = async () => {
    const params = {
      TableName: "passgobblers-storage"
    };

    try {
      const command = new ScanCommand(params);
      const result = await docClient.send(command);
      const decryptedPasswords = result.Items.map(item => ({
        ...item,
        password: decryptPassword(item.password)
      }));
      setPasswords(decryptedPasswords);
    } catch (error) {
      console.error("Error fetching passwords:", error);
      console.error("Error details:", JSON.stringify(error, null, 2));
    }
  };

  const generatePassword = () => {
    const length = 16;
    const charset =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+~`|}{[]:;?><,./-=";
    let password = "";
    for (let i = 0; i < length; i++) {
      password += charset.charAt(Math.floor(Math.random() * charset.length));
    }
    setNewPassword(password);
  };

  const addPassword = async () => {
    if (newSite && newUsername && newPassword) {
      const encryptedPassword = encryptPassword(newPassword);
      const newItem = {
        site: newSite,
        username: newUsername,
        password: encryptedPassword
      };

      const params = {
        TableName: "passgobblers-storage",
        Item: newItem
      };

      try {
        const command = new PutCommand(params);
        await docClient.send(command);
        setPasswords([...passwords, { ...newItem, password: newPassword }]);
        setNewSite("");
        setNewUsername("");
        setNewPassword("");
      } catch (error) {
        console.error("Error adding password:", error);
        console.error("Error details:", JSON.stringify(error, null, 2));
      }
    }
  };

  const initiateDelete = (index) => {
    setDeleteConfirmation({ ...deleteConfirmation, [index]: true });
  };

  const cancelDelete = (index) => {
    setDeleteConfirmation({ ...deleteConfirmation, [index]: false });
  };

  const confirmDelete = async (index) => {
    const itemToDelete = passwords[index];
    const params = {
      TableName: "passgobblers-storage",
      Key: {
        site: itemToDelete.site,
        username: itemToDelete.username
      }
    };

    try {
      const command = new DeleteCommand(params);
      await docClient.send(command);
      setPasswords(passwords.filter((_, i) => i !== index));
      setDeleteConfirmation({ ...deleteConfirmation, [index]: false });
    } catch (error) {
      console.error("Error deleting password:", error);
    }
  };

  const togglePasswordVisibility = (index) => {
    setShowPassword({ ...showPassword, [index]: !showPassword[index] });
  };

  const copyToClipboard = (text, field, index) => {
    navigator.clipboard.writeText(text).then(() => {
      setCopiedStates({ ...copiedStates, [`${field}-${index}`]: true });
      setTimeout(() => {
        setCopiedStates((prev) => ({ ...prev, [`${field}-${index}`]: false }));
      }, 2000);
    });
  };

  const filteredPasswords = passwords.filter(
    (pwd) =>
      pwd.site.toLowerCase().includes(searchTerm.toLowerCase()) ||
      pwd.username.toLowerCase().includes(searchTerm.toLowerCase()),
  );

  return (
    <div className="bg-gray-100 min-h-screen p-8 relative">
      <BackgroundAnimation />
      <div className="max-w-4xl mx-auto bg-opacity-90 rounded-lg shadow-lg p-6 relative z-10">
        <div className="max-w-4xl mx-auto bg-white rounded-lg shadow-lg p-6">
          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              marginBottom: "20px",
            }}
          >
            <img
              src={logo}
              alt="PassGobblers Logo"
              style={{ width: "320px", height: "320px", marginRight: "10px" }}
            />
            <div className="bg-indigo-50 p-4 rounded-lg mb-6">
              <h2 className="text-xl font-semibold mb-4 text-indigo-800">
                Add New Password (❁´◡`❁)
              </h2>
              <input
                type="text"
                placeholder="Website"
                value={newSite}
                onChange={(e) => setNewSite(e.target.value)}
                className="w-full p-2 mb-2 rounded border border-indigo-200"
              />
              <input
                type="text"
                placeholder="Username"
                value={newUsername}
                onChange={(e) => setNewUsername(e.target.value)}
                className="w-full p-2 mb-2 rounded border border-indigo-200"
              />
              <div className="flex mb-4">
                <input
                  type="password"
                  placeholder="Password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  className="flex-grow p-2 rounded-l border border-indigo-200"
                />
                <button
                  onClick={generatePassword}
                  className="bg-indigo-600 text-white px-3 rounded-r hover:bg-indigo-700 transition duration-300 flex items-center justify-center"
                >
                  <RefreshCw size={18} />
                </button>
              </div>
              <button
                onClick={addPassword}
                className="w-full bg-indigo-600 text-white py-3 rounded hover:bg-indigo-700 transition duration-300 flex items-center justify-center"
              >
                <Plus size={18} className="mr-2" /> Add Password
              </button>
            </div>
          </div>

          <div className="mb-6">
            <div className="flex items-center bg-gray-100 rounded-lg p-2">
              <Search className="text-gray-400 mr-2" />
              <input
                type="text"
                placeholder="Search passwords..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="bg-transparent w-full focus:outline-none"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {filteredPasswords.map((pwd, index) => (
              <div
                key={index}
                className={`bg-white p-4 rounded-lg shadow transition duration-300 ${
                  searchTerm &&
                  (pwd.site.toLowerCase().includes(searchTerm.toLowerCase()) ||
                    pwd.username
                      .toLowerCase()
                      .includes(searchTerm.toLowerCase()))
                    ? "ring-2 ring-indigo-500 ring-opacity-50"
                    : ""
                }`}
              >
                <div className="flex justify-between items-center mb-2">
                  <h3 className="text-lg font-semibold text-indigo-800">
                    {pwd.site}
                  </h3>
                  {deleteConfirmation[index] ? (
                    <div className="flex items-center">
                      <span className="text-sm mr-2">Delete?</span>
                      <button
                        onClick={() => confirmDelete(index)}
                        className="text-green-600 hover:text-green-800 mr-2"
                      >
                        <Check size={18} />
                      </button>
                      <button
                        onClick={() => cancelDelete(index)}
                        className="text-red-600 hover:text-red-800"
                      >
                        <X size={18} />
                      </button>
                    </div>
                  ) : (
                    <button
                      onClick={() => initiateDelete(index)}
                      className="text-gray-400 hover:text-red-600 transition-colors duration-200"
                    >
                      <Trash2 size={18} />
                    </button>
                  )}
                </div>
                <div className="flex items-center mb-2">
                  <span className="font-medium mr-2">Username:</span>
                  <span className="flex-grow">{pwd.username}</span>
                  <button
                    onClick={() =>
                      copyToClipboard(pwd.username, "username", index)
                    }
                    className="text-indigo-600 hover:text-indigo-800 relative"
                  >
                    {copiedStates[`username-${index}`] ? (
                      <Check size={18} className="text-green-500" />
                    ) : (
                      <Copy size={18} />
                    )}
                    {copiedStates[`username-${index}`] && (
                      <span className="absolute -top-8 left-1/2 transform -translate-x-1/2 bg-green-500 text-white text-xs py-1 px-2 rounded">
                        Copied!
                      </span>
                    )}
                  </button>
                </div>
                <div className="flex items-center mb-4">
                  <span className="font-medium mr-2">Password:</span>
                  <span className="flex-grow">
                    {showPassword[index] ? pwd.password : "••••••••"}
                  </span>
                  <button
                    onClick={() => togglePasswordVisibility(index)}
                    className="text-indigo-600 hover:text-indigo-800 mr-2"
                  >
                    {showPassword[index] ? (
                      <EyeOff size={18} />
                    ) : (
                      <Eye size={18} />
                    )}
                  </button>
                  <button
                    onClick={() =>
                      copyToClipboard(pwd.password, "password", index)
                    }
                    className="text-indigo-600 hover:text-indigo-800 relative"
                  >
                    {copiedStates[`password-${index}`] ? (
                      <Check size={18} className="text-green-500" />
                    ) : (
                      <Copy size={18} />
                    )}
                    {copiedStates[`password-${index}`] && (
                      <span className="absolute -top-8 left-1/2 transform -translate-x-1/2 bg-green-500 text-white text-xs py-1 px-2 rounded">
                        Copied!
                      </span>
                    )}
                  </button>
                </div>
              </div>
            ))}
          </div>
          <div className="mt-10 text-center">
            <p className="text-gray-600">
              Made with <span className="text-red-500">❤️‍🔥</span> by{" "}
              <a
                href="https://github.com/dhruvnotfound"
                target="_blank"
                rel="noopener noreferrer"
                className="text-indigo-600 hover:text-indigo-800"
              >
                dhruvnotfound
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PassGobbler;