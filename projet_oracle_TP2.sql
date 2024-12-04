-------------------------------------------------------------------------------------
-- Organisation des étudiants en groupes et leur emploi du temps
-- Auteur : THIAM Papa M1 Informatique - 2024
-------------------------------------------------------------------------------------

-- Suppression des tables si elles existent déjà
DROP TABLE Emploi_du_Temps CASCADE CONSTRAINTS;
DROP TABLE UE_Specialite CASCADE CONSTRAINTS;
DROP TABLE Groupe CASCADE CONSTRAINTS;
DROP TABLE UE CASCADE CONSTRAINTS;
DROP TABLE Etudiant CASCADE CONSTRAINTS;
DROP TABLE Specialite CASCADE CONSTRAINTS;

-- Suppression des types si ils existent déjà
DROP TYPE edt_type FORCE;
DROP TYPE specialite_type FORCE;
DROP TYPE etudiant_type FORCE;
DROP TYPE edt_table_type FORCE;
/

-- Type pour la spécialité
CREATE OR REPLACE TYPE specialite_type AS OBJECT (
                                                     nom_specialite VARCHAR2(50),
                                                     origine VARCHAR2(50)
                                                 );
/

-- Type pour les emplois du temps
CREATE OR REPLACE TYPE edt_type AS OBJECT (
                                              jour_semaine VARCHAR2(10),    -- Jour de la semaine (Lundi, Mardi, ...)
                                              horaire NUMBER(1),            -- Heure (1, 2, 3, 4)
                                              cours VARCHAR2(100),         -- Nom du cours (ex: programmation)
                                              type_cours VARCHAR2(2),      -- CM, TD ou TP
                                              num_groupe NUMBER(1)         -- Numéro de groupe
                                          );
/

-- Type pour les étudiants
CREATE OR REPLACE TYPE etudiant_type AS OBJECT (
                                                   nom VARCHAR2(50),
                                                   prenom VARCHAR2(50),
                                                   origine VARCHAR2(50),
                                                   specialite REF specialite_type,  -- Référence vers la spécialité
                                                   emploi_du_temps SYS.ODCIVARCHAR2LIST  -- Liste des emplois du temps (utilise une collection de chaînes)
                                               );
/

-- Type pour une table d'emplois du temps (une collection de edt_type)
CREATE OR REPLACE TYPE edt_table_type AS TABLE OF edt_type;
/

-- Table pour les spécialités
CREATE TABLE specialites OF specialite_type;

-- Table pour les étudiants avec une référence vers la spécialité
CREATE TABLE etudiants OF etudiant_type;

-- Table pour les emplois du temps
CREATE TABLE emplois_du_temps OF edt_type;

-- Table pour les Unités d'Enseignement (UE)
CREATE TABLE UE (
                    Nom_UE VARCHAR2(10) PRIMARY KEY,
                    Nom_CM VARCHAR2(50) NOT NULL,
                    Enseignant VARCHAR2(100) NOT NULL -- Nom de l'enseignant
);
/

-- Table pour stocker les spécialités
CREATE TABLE Specialite (
                            ID_Specialite NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Clé primaire auto-générée
                            Nom_Specialite VARCHAR2(50) NOT NULL, -- Nom de la spécialité
                            Origine VARCHAR2(50) CHECK (Origine IN ('Parcoursup', 'Etudes_en_France', 'Autres')) NOT NULL -- Origine de la spécialité
);
/

-- Table pour stocker les groupes TD et TP
CREATE TABLE Groupe (
                        ID_Groupe VARCHAR2(10) PRIMARY KEY, -- Clé primaire
                        Nom_UE VARCHAR2(10) NOT NULL, -- Référence à l'UE
                        Effectif INT NOT NULL,
                        Type_Cours VARCHAR2(2) CHECK (Type_Cours IN ('TD', 'TP')) NOT NULL -- Indicateur TD ou TP
);
/

-- Table pour relier les UE aux spécialités
CREATE TABLE UE_Specialite (
                               ID_UE_Specialite NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Clé primaire auto-générée
                               Nom_UE VARCHAR2(10) NOT NULL,
                               Specialite_ID NUMBER NOT NULL,
                               FOREIGN KEY (Nom_UE) REFERENCES UE(Nom_UE), -- Clé étrangère vers UE
                               FOREIGN KEY (Specialite_ID) REFERENCES Specialite(ID_Specialite) -- Clé étrangère vers Spécialité
);
/

-- Table pour stocker les emplois du temps
CREATE TABLE Emploi_du_Temps (
                                 ID_Emploi NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                 Nom_UE VARCHAR2(10) NOT NULL,
                                 Type_Cours VARCHAR2(10) CHECK (Type_Cours IN ('CM', 'TD', 'TP')),
                                 Jour VARCHAR2(15),
                                 Heure_Debut DATE,
                                 Heure_Fin DATE,
                                 Num_Groupe NUMBER(1)
);
/

-- Table pour stocker les étudiants
CREATE TABLE Etudiant (
                          ID_Etudiant NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                          Nom VARCHAR2(50) NOT NULL,
                          Prenom VARCHAR2(50) NOT NULL,
                          Identifiant VARCHAR2(8) UNIQUE,
                          Origine VARCHAR2(50) CHECK (Origine IN ('Parcoursup', 'Etudes_en_France', 'Autres')) NOT NULL,
                          Specialite_ID NUMBER,
                          Emploi_du_Temps edt_table_type,
                          FOREIGN KEY (Specialite_ID) REFERENCES Specialite(ID_Specialite)
)
    NESTED TABLE Emploi_du_Temps STORE AS Emploi_Nested_Table;
/


-------------------------------------------------------------------------------------
-- Fonction de répartition des étudiants dans les groupes
-------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE repartir_etudiants_par_groupe AS
    CURSOR c_etudiants IS
        SELECT e.ID_Etudiant, e.Specialite_ID
        FROM Etudiant e
        ORDER BY e.Specialite_ID, e.ID_Etudiant;

    CURSOR c_groupes (specialite_id NUMBER, type_cours VARCHAR2) IS
        SELECT g.ID_Groupe, g.Type_Cours, g.Effectif
        FROM Groupe g
                 JOIN UE_Specialite us ON g.Nom_UE = us.Nom_UE
        WHERE us.Specialite_ID = specialite_id
          AND g.Type_Cours = type_cours
          AND ((type_cours = 'TD' AND g.Effectif < 40) OR (type_cours = 'TP' AND g.Effectif < 20))
        ORDER BY g.ID_Groupe;

    v_num_groupe NUMBER;
    v_type_cours VARCHAR2(2);
    v_effectif_max NUMBER;
    v_groupes_effectifs INT;
BEGIN
    FOR etudiant IN c_etudiants LOOP
        IF etudiant.Specialite_ID = 1 THEN
            v_type_cours := 'TD';
            v_effectif_max := 40; -- Effectif maximum pour les TD
        ELSE
            v_type_cours := 'TP';
            v_effectif_max := 20; -- Effectif maximum pour les TP
        END IF;

        v_groupes_effectifs := 0;
        -- On cherche un groupe avec de la place
        FOR groupe IN c_groupes(etudiant.Specialite_ID, v_type_cours) LOOP
            IF v_groupes_effectifs = 0 THEN
                v_num_groupe := groupe.ID_Groupe;
                v_groupes_effectifs := groupe.Effectif;
            ELSIF groupe.Effectif < v_effectif_max THEN
                v_num_groupe := groupe.ID_Groupe;
                v_groupes_effectifs := groupe.Effectif;
            END IF;
        END LOOP;

        -- Si on a trouvé un groupe avec de la place, on ajoute l'étudiant
        IF v_groupes_effectifs < v_effectif_max THEN
            INSERT INTO Etudiant (ID_Etudiant, Nom, Prenom, Identifiant, Origine, Specialite_ID, Emploi_du_Temps)
            VALUES (etudiant.ID_Etudiant, etudiant.Nom, etudiant.Prenom, etudiant.Identifiant, etudiant.Origine, etudiant.Specialite_ID, etudiant.Emploi_du_Temps);
        END IF;
    END LOOP;
END repartir_etudiants_par_groupe;
/




--Insertion des données
-- Insertion des UE
INSERT INTO UE VALUES ('INFO1', 'Programmation', 'M. Faye');
INSERT INTO UE VALUES ('INFO2', 'Algorithmique', 'M. Diop');
INSERT INTO UE VALUES ('MATH1', 'Algèbre', 'M. Sow');
INSERT INTO UE VALUES ('PHYS1', 'Mécanique', 'M. Ndiaye');
SELECT * FROM UE;

-- Insertion des spécialités
INSERT INTO Specialite (Nom_Specialite, Origine) VALUES ('Informatique', 'Parcoursup');
INSERT INTO Specialite (Nom_Specialite, Origine) VALUES ('Mathématiques', 'Parcoursup');
INSERT INTO Specialite (Nom_Specialite, Origine) VALUES ('Physique', 'Etudes_en_France');
INSERT INTO Specialite (Nom_Specialite, Origine) VALUES ('Chimie', 'Autres');
SELECT * FROM Specialite;

-- Insertion des groupes
INSERT INTO Groupe VALUES ('G1', 'INFO1', 30, 'TD');
INSERT INTO Groupe VALUES ('G2', 'INFO1', 25, 'TP');
INSERT INTO Groupe VALUES ('G3', 'INFO2', 29, 'TD');
INSERT INTO Groupe VALUES ('G4', 'INFO2', 26, 'TP');
INSERT INTO Groupe VALUES ('G5', 'MATH1', 30, 'TD');
-- TRUNCATE TABLE Groupe;
SELECT * FROM Groupe;

-- Insertion des emplois du temps
INSERT INTO Emploi_du_Temps (Nom_UE, Type_Cours, Jour, Heure_Debut, Heure_Fin, Num_Groupe)
VALUES ('INFO1', 'CM', 'Lundi', TO_DATE('08:00:00', 'HH24:MI:SS'), TO_DATE('10:00:00', 'HH24:MI:SS'), 0);
INSERT INTO Emploi_du_Temps (Nom_UE, Type_Cours, Jour, Heure_Debut, Heure_Fin, Num_Groupe)
VALUES ('INFO1', 'TD', 'Mardi', TO_DATE('10:00:00', 'HH24:MI:SS'), TO_DATE('12:00:00', 'HH24:MI:SS'), 1);
INSERT INTO Emploi_du_Temps (Nom_UE, Type_Cours, Jour, Heure_Debut, Heure_Fin, Num_Groupe)
VALUES ('INFO1', 'TP', 'Mardi', TO_DATE('14:00:00', 'HH24:MI:SS'), TO_DATE('16:00:00', 'HH24:MI:SS'), 2);
INSERT INTO Emploi_du_Temps (Nom_UE, Type_Cours, Jour, Heure_Debut, Heure_Fin, Num_Groupe)
VALUES ('INFO2', 'CM', 'Mercredi', TO_DATE('08:00:00', 'HH24:MI:SS'), TO_DATE('10:00:00', 'HH24:MI:SS'), 0);
INSERT INTO Emploi_du_Temps (Nom_UE, Type_Cours, Jour, Heure_Debut, Heure_Fin, Num_Groupe)
VALUES ('INFO2', 'TD', 'Mercredi', TO_DATE('10:00:00', 'HH24:MI:SS'), TO_DATE('12:00:00', 'HH24:MI:SS'), 3);
INSERT INTO Emploi_du_Temps (Nom_UE, Type_Cours, Jour, Heure_Debut, Heure_Fin, Num_Groupe)
VALUES ('INFO2', 'TP', 'Mercredi', TO_DATE('14:00:00', 'HH24:MI:SS'), TO_DATE('16:00:00', 'HH24:MI:SS'), 4);
INSERT INTO Emploi_du_Temps (Nom_UE, Type_Cours, Jour, Heure_Debut, Heure_Fin, Num_Groupe)
VALUES ('MATH1', 'CM', 'Jeudi', TO_DATE('08:00:00', 'HH24:MI:SS'), TO_DATE('10:00:00', 'HH24:MI:SS'), 0);
INSERT INTO Emploi_du_Temps (Nom_UE, Type_Cours, Jour, Heure_Debut, Heure_Fin, Num_Groupe)
VALUES ('MATH1', 'TD', 'Jeudi', TO_DATE('10:00:00', 'HH24:MI:SS'), TO_DATE('12:00:00', 'HH24:MI:SS'), 5);
INSERT INTO Emploi_du_Temps (Nom_UE, Type_Cours, Jour, Heure_Debut, Heure_Fin, Num_Groupe)
VALUES ('PHYS1', 'CM', 'Vendredi', TO_DATE('08:00:00', 'HH24:MI:SS'), TO_DATE('10:00:00', 'HH24:MI:SS'), 0);
-- TRUNCATE TABLE Emploi_du_Temps; -- Enlever cette ligne, sauf si vous voulez vraiment tout supprimer
SELECT * FROM Emploi_du_Temps;

-- Insertion des étudiants (en utilisant le type de table imbriquée edt_table_type pour les emplois du temps)
INSERT INTO Etudiant (Nom, Prenom, identifiant, Origine, Specialite_ID, Emploi_du_Temps)
VALUES ('Diop', 'Amy', '20240001', 'Parcoursup', 1, edt_table_type(
        edt_type('Lundi', 1, 'Programmation', 'CM', 0),
        edt_type('Mardi', 2, 'Programmation', 'TD', 1),
        edt_type('Mercredi', 3, 'Programmation', 'TP', 2)
                                        ));

INSERT INTO Etudiant (Nom, Prenom, identifiant, Origine, Specialite_ID, Emploi_du_Temps)
VALUES ('Sow', 'Mamadou', '20240002', 'Parcoursup', 1, edt_table_type(
        edt_type('Lundi', 1, 'Algèbre', 'CM', 0),
        edt_type('Jeudi', 2, 'Algèbre', 'TD', 5)
                                           ));

INSERT INTO Etudiant (Nom, Prenom, identifiant, Origine, Specialite_ID, Emploi_du_Temps)
VALUES ('Ndiaye', 'Fatou', '20240003', 'Etudes_en_France', 3, edt_table_type(
        edt_type('Lundi', 1, 'Mécanique', 'CM', 0),
        edt_type('Vendredi', 2, 'Mécanique', 'CM', 0)
                                                  ));

INSERT INTO Etudiant (Nom, Prenom, identifiant, Origine, Specialite_ID, Emploi_du_Temps)
VALUES ('Faye', 'Sidy', '20240004', 'Autres', 4, edt_table_type(
        edt_type('Lundi', 1, 'Chimie', 'CM', 0)
                                     ));

INSERT INTO Etudiant (Nom, Prenom, identifiant, Origine, Specialite_ID, Emploi_du_Temps)
VALUES ('Thiam', 'Papa', '20240005', 'Parcoursup', 1, edt_table_type(
        edt_type('Lundi', 1, 'Programmation', 'CM', 0),
        edt_type('Mardi', 2, 'Programmation', 'TD', 1),
        edt_type('Mercredi', 3, 'Programmation', 'TP', 2)
                                          ));

INSERT INTO Etudiant (Nom, Prenom, identifiant, Origine, Specialite_ID, Emploi_du_Temps)
VALUES ('Diop', 'Amy', '20240006', 'Parcoursup', 1, edt_table_type(
        edt_type('Lundi', 1, 'Programmation', 'CM', 0),
        edt_type('Mardi', 2, 'Programmation', 'TD', 1),
        edt_type('Mercredi', 3, 'Programmation', 'TP', 2),
        edt_type('Jeudi', 4, 'Algèbre', 'CM', 0),
        edt_type('Vendredi', 5, 'Mécanique', 'CM', 0)
                                        ));

-- Vérification des résultats
SELECT * FROM Etudiant;


-- Affichage des emplois du temps des étudiants
SELECT e.Nom, e.Prenom, e.Origine, e.Specialite_ID, e.Emploi_du_Temps
    FROM Etudiant e;

-- Tous les etudiants qui ont cours le lundi
SELECT e.Nom, e.Prenom, e.Origine, e.Specialite_ID, e.Emploi_du_Temps
    FROM Etudiant e, TABLE(e.Emploi_du_Temps) edt
            WHERE edt.jour_semaine = 'Lundi';

-- Le nombre d'étudiants par spécialité
SELECT s.Nom_Specialite, COUNT(e.ID_Etudiant) AS Nombre_Etudiants
    FROM Specialite s, Etudiant e
        WHERE s.ID_Specialite = e.Specialite_ID GROUP BY s.Nom_Specialite;

-- Les groupes de TD et TP pour chaque UE
SELECT u.Nom_UE, g.ID_Groupe, g.Effectif, g.Type_Cours
    FROM UE u, Groupe g WHERE u.Nom_UE = g.Nom_UE;

--le nombre d'étudiants par groupe
SELECT g.ID_Groupe, COUNT(e.ID_Etudiant) AS Nombre_Etudiants
    FROM Groupe g, Etudiant e
        WHERE g.ID_Groupe = e.ID_Etudiant GROUP BY g.ID_Groupe;

-- Les professeurs qui enseignent le lundi
SELECT DISTINCT u.Enseignant
    FROM UE u, Emploi_du_Temps edt
        WHERE u.Nom_UE = edt.Nom_UE AND edt.Jour = 'Lundi';

-- Les étudiants et qui ont CM le lundi
SELECT e.Nom, e.Prenom, e.Origine, e.Specialite_ID, e.Emploi_du_Temps
        FROM Etudiant e, TABLE(e.Emploi_du_Temps) edt WHERE edt.jour_semaine = 'Lundi' AND edt.type_cours = 'CM';

-- Les étudiants  et leurs groupes respectifs qui ont cours le mardi
SELECT e.Nom, e.Prenom, e.Origine, e.Specialite_ID, e.Emploi_du_Temps, edt.num_groupe FROM Etudiant e, TABLE(e.Emploi_du_Temps) edt WHERE edt.jour_semaine = 'Mardi';

-- Les étudiants et leurs groupes respectifs qui ont cours le mercredi
SELECT e.Nom, e.Prenom, e.Origine, e.Specialite_ID, e.Emploi_du_Temps, edt.num_groupe FROM Etudiant e, TABLE(e.Emploi_du_Temps) edt WHERE edt.jour_semaine = 'Mercredi';

-- Les cours de la semaine, date et les étudiants qui y assistent
SELECT edt.jour_semaine, edt.horaire, edt.cours, edt.type_cours, edt.num_groupe, e.Nom, e.Prenom
    FROM Etudiant e, TABLE(e.Emploi_du_Temps) edt;

-- les cours de la semaine, professeur et les étudiants qui y assistent
SELECT edt.jour_semaine, edt.horaire, edt.cours, edt.type_cours, edt.num_groupe, u.Enseignant, e.Nom, e.Prenom
    FROM Etudiant e, TABLE(e.Emploi_du_Temps) edt, UE u
        WHERE edt.cours = u.Nom_CM;


-- Les cours de la semaine, professeur, les étudiants qui y assistent et le nombre d'étudiants
SELECT edt.jour_semaine, edt.horaire, edt.cours, edt.type_cours, edt.num_groupe, u.Enseignant, COUNT(e.ID_Etudiant) AS Nombre_Etudiants
    FROM Etudiant e, TABLE(e.Emploi_du_Temps) edt, UE u
        WHERE edt.cours = u.Nom_CM GROUP BY edt.jour_semaine, edt.horaire, edt.cours, edt.type_cours, edt.num_groupe, u.Enseignant;
