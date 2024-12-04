-------------------------------------------------------------------------------------
-- Organisation des étudiants en groupes et leur emploi du temps
-- Auteur : THIAM Papa M1 Informatique - 2024
-------------------------------------------------------------------------------------

-- Suppression des tables si elles existent déjà
DROP TABLE IF EXISTS Emploi_du_Temps CASCADE;
DROP TABLE IF EXISTS UE_Specialite CASCADE;
DROP TABLE IF EXISTS Groupe_TP CASCADE;
DROP TABLE IF EXISTS Groupe_TD CASCADE;
DROP TABLE IF EXISTS UE CASCADE;
DROP TABLE IF EXISTS Specialite CASCADE;
DROP TABLE IF EXISTS Etudiant CASCADE;

-- Création de la table UE
CREATE TABLE UE (
                    Nom_UE VARCHAR(10) PRIMARY KEY, -- Clé primaire
                    Nom_CM VARCHAR(50) NOT NULL, -- Nom du cours magistral
                    Enseignant VARCHAR(100) NOT NULL -- Enseignant
);

-- Création de la table Specialite
CREATE TABLE Specialite (
                            ID_Specialite INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY, -- Clé primaire auto-incrémentée
                            Nom_Specialite VARCHAR(50) NOT NULL, -- Nom de la spécialité
                            Origine VARCHAR(50) CHECK (Origine IN ('Parcoursup', 'Etudes_en_France', 'Autres')) NOT NULL -- Origine de la spécialité
);

-- Création de la table Groupe_TD
CREATE TABLE Groupe_TD (
                           ID_TD VARCHAR(10) PRIMARY KEY, -- Clé primaire
                           Nom_UE VARCHAR(10) NOT NULL, -- Nom de l'UE
                           Effectif INT NOT NULL, -- Effectif du groupe TD
                           FOREIGN KEY (Nom_UE) REFERENCES UE(Nom_UE) -- Clé étrangère vers UE
);

-- Création de la table Groupe_TP
CREATE TABLE Groupe_TP (
                           ID_TP VARCHAR(10) PRIMARY KEY, -- Clé primaire
                           Nom_UE VARCHAR(10) NOT NULL, -- Nom de l'UE
                           Effectif INT NOT NULL, -- Effectif du groupe TP
                           FOREIGN KEY (Nom_UE) REFERENCES UE(Nom_UE) -- Clé étrangère vers UE
);

-- Création de la table UE_Specialite
CREATE TABLE UE_Specialite (
                               ID_UE_Specialite INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY, -- Clé primaire auto-incrémentée
                               Nom_UE VARCHAR(10) NOT NULL, -- Nom de l'UE
                               Specialite_ID INT NOT NULL, -- ID de la spécialité
                               FOREIGN KEY (Nom_UE) REFERENCES UE(Nom_UE), -- Clé étrangère vers UE
                               FOREIGN KEY (Specialite_ID) REFERENCES Specialite(ID_Specialite) -- Clé étrangère vers Specialite
);

-- Création de la table Emploi_du_Temps
CREATE TABLE Emploi_du_Temps (
                                 Nom_UE VARCHAR(10) NOT NULL, -- Nom de l'UE
                                 Type_Cours VARCHAR(10) CHECK (Type_Cours IN ('CM', 'TD', 'TP')) NOT NULL, -- Type de cours
                                 Jour VARCHAR(15) NOT NULL, -- Jour du cours
                                 Heure_Debut TIME NOT NULL, -- Heure de début
                                 Heure_Fin TIME NOT NULL, -- Heure de fin
                                 FOREIGN KEY (Nom_UE) REFERENCES UE(Nom_UE) -- Clé étrangère vers UE
);

-- Création de la table Etudiant
CREATE TABLE Etudiant (
                          ID_Etudiant INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY, -- Clé primaire auto-incrémentée
                          Nom VARCHAR(50) NOT NULL, -- Nom de l'étudiant
                          Prenom VARCHAR(50) NOT NULL, -- Prénom de l'étudiant
                          UE_Courant VARCHAR(10) NOT NULL, -- UE courante
                          Groupe_TD VARCHAR(10) NOT NULL, -- Groupe TD
                          Groupe_TP VARCHAR(10) NOT NULL, -- Groupe TP
                          Emploi_du_Temps TEXT NOT NULL, -- Emploi du temps
                          Origine VARCHAR(50) CHECK (Origine IN ('Parcoursup', 'Etudes_en_France', 'Autres')) NOT NULL, -- Origine
                          Specialite_ID INT NOT NULL, -- ID de la spécialité
                          FOREIGN KEY (UE_Courant) REFERENCES UE(Nom_UE), -- Clé étrangère vers UE
                          FOREIGN KEY (Groupe_TD) REFERENCES Groupe_TD(ID_TD), -- Clé étrangère vers Groupe_TD
                          FOREIGN KEY (Groupe_TP) REFERENCES Groupe_TP(ID_TP), -- Clé étrangère vers Groupe_TP
                          FOREIGN KEY (Specialite_ID) REFERENCES Specialite(ID_Specialite) -- Clé étrangère vers Specialite
);


-- Insertion des données dans la table UE
INSERT INTO UE (Nom_UE, Nom_CM, Enseignant) VALUES
('UE1', 'Algorithmique', 'M. DUPONT'),
('UE2', 'Base de données', 'M. Amanton'),
('UE3', 'Réseaux', 'M. DURAND'),
('UE4', 'Système d''exploitation', 'M. DUBOIS'),
('UE5', 'Programmation Web', 'M. LEROY');

-- Insertion des données dans la table Specialite
INSERT INTO Specialite (Nom_Specialite, Origine) VALUES
('Informatique', 'Parcoursup'),
('Informatique', 'Etudes_en_France'),
('Physique', 'Autres'),
('Chimie', 'Parcoursup'),
('Chimie', 'Etudes_en_France'),
('Mathématiques', 'Autres'),
('Biologie', 'Parcoursup'),
('Biologie', 'Etudes_en_France'),
('Géographie', 'Autres'),
('Langues', 'Parcoursup'),
('Langues', 'Etudes_en_France'),
('Littérature', 'Autres'),
('Philosophie', 'Parcoursup');

-- Insertion des données dans la table Groupe_TD
INSERT INTO Groupe_TD (ID_TD, Nom_UE, Effectif) VALUES
('TD1', 'UE1', 30),
('TD2', 'UE2', 25),
('TD3', 'UE3', 20),
('TD4', 'UE4', 15),
('TD5', 'UE5', 10);


-- Insertion des données dans la table Groupe_TP
INSERT INTO Groupe_TP (ID_TP, Nom_UE, Effectif) VALUES
('TP1', 'UE1', 20),
('TP2', 'UE2', 15),
('TP3', 'UE3', 10),
('TP4', 'UE4', 5),
('TP5', 'UE5', 3);

-- Insertion des données dans la table UE_Specialite
INSERT INTO UE_Specialite (Nom_UE, Specialite_ID) VALUES
('UE1', 1),
('UE2', 1),
('UE3', 1),
('UE4', 1),
('UE5', 1),
('UE1', 2),
('UE2', 2),
('UE3', 2),
('UE4', 2),
('UE5', 2),
('UE1', 3),
('UE2', 3),
('UE3', 3),
('UE4', 3),
('UE5', 3),
('UE1', 4),
('UE2', 4),
('UE3', 4),
('UE4', 4),
('UE5', 4),
('UE1', 5),
('UE2', 5),
('UE3', 5),
('UE4', 5),
('UE5', 5);


-- Insertion des données dans la table Emploi_du_Temps
INSERT INTO Emploi_du_Temps (Nom_UE, Type_Cours, Jour, Heure_Debut, Heure_Fin) VALUES
('UE1', 'CM', 'Lundi', '08:00', '10:00'),
('UE1', 'TD', 'Mardi', '10:00', '12:00'),
('UE1', 'TP', 'Mercredi', '14:00', '16:00'),
('UE2', 'CM', 'Jeudi', '08:00', '10:00'),
('UE2', 'TD', 'Vendredi', '10:00', '12:00'),
('UE2', 'TP', 'Samedi', '14:00', '16:00'),
('UE3', 'CM', 'Dimanche', '08:00', '10:00'),
('UE3', 'TD', 'Lundi', '10:00', '12:00'),
('UE3', 'TP', 'Mardi', '14:00', '16:00'),
('UE4', 'CM', 'Mercredi', '08:00', '10:00'),
('UE4', 'TD', 'Jeudi', '10:00', '12:00'),
('UE4', 'TP', 'Vendredi', '14:00', '16:00'),
('UE5', 'CM', 'Samedi', '08:00', '10:00'),
('UE5', 'TD', 'Dimanche', '10:00', '12:00'),
('UE5', 'TP', 'Lundi', '14:00', '16:00');

-- Insertion des données dans la table Etudiant
INSERT INTO Etudiant (Nom, Prenom, UE_Courant, Groupe_TD, Groupe_TP, Emploi_du_Temps, Origine, Specialite_ID) VALUES
('THIAM', 'Papa', 'UE1', 'TD1', 'TP1', 'Lundi:08:00-10:00', 'Parcoursup', 1),
('DIOP', 'Mamadou', 'UE2', 'TD2', 'TP2', 'Mardi:10:00-12:00', 'Etudes_en_France', 2),
('DIALLO', 'Aminata', 'UE3', 'TD3', 'TP3', 'Mercredi:14:00-16:00', 'Autres', 3),
('FALL', 'Moussa', 'UE4', 'TD4', 'TP4', 'Jeudi:08:00-10:00', 'Parcoursup', 4),
('DIOUF', 'Fatou', 'UE5', 'TD5', 'TP5', 'Vendredi:10:00-12:00', 'Etudes_en_France', 5);

