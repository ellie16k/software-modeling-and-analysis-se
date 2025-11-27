CREATE DATABASE IF NOT EXISTS opentable_DB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE opentable_DB;


CREATE TABLE Role (
    role_ID         INT AUTO_INCREMENT PRIMARY KEY,
    rolename        VARCHAR(50)  NOT NULL,
    roledescription VARCHAR(255) NULL
) ENGINE=InnoDB;

CREATE TABLE `User` (
    user_ID           INT AUTO_INCREMENT PRIMARY KEY,
    role_ID           INT         NOT NULL,
    userFirstName     VARCHAR(50)  NOT NULL,
    userLastName      VARCHAR(50)  NOT NULL,
    userEmail         VARCHAR(100) NOT NULL,
    userPhone         VARCHAR(20)  NULL,
    userPasswordHash  VARCHAR(255) NOT NULL,
    userCreatedAt     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_user_role
        FOREIGN KEY (role_ID) REFERENCES Role(role_ID),

    CONSTRAINT uq_user_email UNIQUE (userEmail)
) ENGINE=InnoDB;

CREATE TABLE Restaurant (
    restaurant_ID        INT AUTO_INCREMENT PRIMARY KEY,
    restaurantName       VARCHAR(100) NOT NULL,
    restaurantDescription TEXT        NULL,
    restaurantAddress    VARCHAR(200) NOT NULL,
    restaurantCity       VARCHAR(100) NOT NULL,
    restaurantCountry    VARCHAR(100) NOT NULL,
    restaurantCapacity   INT          NOT NULL,
    restaurantMinPeople  INT          NOT NULL,
    restaurantMaxPeople  INT          NOT NULL,
    restaurantCreatedAt  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE RestaurantOwnership (
    restaurantOwnership_ID INT AUTO_INCREMENT PRIMARY KEY,
    user_ID                INT NOT NULL,
    restaurant_ID          INT NOT NULL,

    CONSTRAINT fk_ownership_user
        FOREIGN KEY (user_ID) REFERENCES `User`(user_ID),
    CONSTRAINT fk_ownership_restaurant
        FOREIGN KEY (restaurant_ID) REFERENCES Restaurant(restaurant_ID)
) ENGINE=InnoDB;

CREATE TABLE `Table` (
    table_ID           INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_ID      INT NOT NULL,
    tableNumber        INT NOT NULL,
    tableMinCapacity   INT NOT NULL,
    tableMaxCapacity   INT NOT NULL,
    tableLocation      VARCHAR(50) NOT NULL,

    CONSTRAINT fk_table_restaurant
        FOREIGN KEY (restaurant_ID) REFERENCES Restaurant(restaurant_ID)
) ENGINE=InnoDB;

CREATE TABLE Reservation (
    reservation_ID          INT AUTO_INCREMENT PRIMARY KEY,
    user_ID                 INT       NOT NULL,
    restaurant_ID           INT       NOT NULL,
    table_ID                INT       NOT NULL,
    reservationDateTime     DATETIME  NOT NULL,
    reservationGuestCount   INT       NOT NULL,
    reservationStatus       ENUM('Pending','Confirmed','Cancelled','Completed','NoShow')
                             NOT NULL DEFAULT 'Pending',
    reservationCreatedAt    DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reservationCancelledAt  DATETIME  NULL,
    reservationConfirmedAt  DATETIME  NULL,

    CONSTRAINT fk_reservation_user
        FOREIGN KEY (user_ID)       REFERENCES `User`(user_ID),
    CONSTRAINT fk_reservation_restaurant
        FOREIGN KEY (restaurant_ID) REFERENCES Restaurant(restaurant_ID),
    CONSTRAINT fk_reservation_table
        FOREIGN KEY (table_ID)      REFERENCES `Table`(table_ID)
) ENGINE=InnoDB;

CREATE TABLE Review (
    review_ID        INT AUTO_INCREMENT PRIMARY KEY,
    reservation_ID   INT       NOT NULL,
    user_ID          INT       NOT NULL,
    restaurant_ID    INT       NOT NULL,
    reviewRating     INT       NOT NULL,
    reviewComment    TEXT      NULL,
    reviewCreatedAt  DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_review_reservation
        FOREIGN KEY (reservation_ID) REFERENCES Reservation(reservation_ID),
    CONSTRAINT fk_review_user
        FOREIGN KEY (user_ID)        REFERENCES `User`(user_ID),
    CONSTRAINT fk_review_restaurant
        FOREIGN KEY (restaurant_ID)  REFERENCES Restaurant(restaurant_ID),

    CONSTRAINT uq_review_reservation UNIQUE (reservation_ID)
) ENGINE=InnoDB;

CREATE TABLE Paymentevent (
    paymentevent_ID   INT AUTO_INCREMENT PRIMARY KEY,
    reservation_ID    INT       NOT NULL,
    paymentEventType  ENUM('LateCancellation','NoShow') NOT NULL,
    paymentEventAmount DECIMAL(10,2) NOT NULL,
    paymentEventTime  DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_paymentevent_reservation
        FOREIGN KEY (reservation_ID) REFERENCES Reservation(reservation_ID)
) ENGINE=InnoDB;

CREATE TABLE Photo (
    photo_ID         INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_ID    INT       NOT NULL,
    photoURL         VARCHAR(255) NOT NULL,
    photoUploadedAt  DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_photo_restaurant
        FOREIGN KEY (restaurant_ID) REFERENCES Restaurant(restaurant_ID)
) ENGINE=InnoDB;

CREATE TABLE Favorite (
    favorite_ID      INT AUTO_INCREMENT PRIMARY KEY,
    user_ID          INT       NOT NULL,
    restaurant_ID    INT       NOT NULL,
    favoriteAddedAt  DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_favorite_user
        FOREIGN KEY (user_ID)       REFERENCES `User`(user_ID),
    CONSTRAINT fk_favorite_restaurant
        FOREIGN KEY (restaurant_ID) REFERENCES Restaurant(restaurant_ID)
) ENGINE=InnoDB;

DELIMITER $$

--  Confirm a reservation:
CREATE PROCEDURE sp_confirm_reservation(IN p_reservation_ID INT)
BEGIN
    UPDATE Reservation
    SET reservationStatus = 'Confirmed',
        reservationConfirmedAt = NOW()
    WHERE reservation_ID = p_reservation_ID
      AND reservationStatus = 'Pending';
END$$

--  Calculate average rating for a restaurant:
CREATE FUNCTION fn_get_restaurant_average_rating(p_restaurant_ID INT)
RETURNS DECIMAL(4,2)
DETERMINISTIC
BEGIN
    DECLARE v_avg DECIMAL(4,2);

    SELECT AVG(reviewRating)
    INTO v_avg
    FROM Review
    WHERE restaurant_ID = p_restaurant_ID;

    RETURN IFNULL(v_avg, 0);
END$$

--  Enforce reservation date rules:
CREATE TRIGGER trg_reservation_before_insert
BEFORE INSERT ON Reservation
FOR EACH ROW
BEGIN
    IF NEW.reservationDateTime < NOW() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Reservation date must be in the future.';
    END IF;

    IF NEW.reservationDateTime > DATE_ADD(NOW(), INTERVAL 30 DAY) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Reservation cannot be more than 30 days in advance.';
    END IF;
END$$

DELIMITER ;



-- DATA INSERTS: 

-- INSERT ROLES: 
INSERT INTO Role (rolename, roledescription) VALUES ('Admin', 'System administrator');
INSERT INTO Role (rolename, roledescription) VALUES ('User', 'Regular customer');
INSERT INTO Role (rolename, roledescription) VALUES ('Owner', 'Restaurant owner');

-- INSERT USERS:
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (1, 'Alex', 'Petrov', 'alex.petrov1@example.com', '+359888663837', 'hash_user_1');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (3, 'Maria', 'Ivanov', 'maria.ivanov2@example.com', '+359883111487', 'hash_user_2');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (3, 'John', 'Dimitrov', 'john.dimitrov3@example.com', '+359886962335', 'hash_user_3');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (3, 'Sofia', 'Georgiev', 'sofia.georgiev4@example.com', '+359887263707', 'hash_user_4');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Peter', 'Kolev', 'peter.kolev5@example.com', '+359881611303', 'hash_user_5');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Ivan', 'Stoyanov', 'ivan.stoyanov6@example.com', '+359882667701', 'hash_user_6');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'George', 'Nikolov', 'george.nikolov7@example.com', '+359881074563', 'hash_user_7');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Elena', 'Popov', 'elena.popov8@example.com', '+359884834076', 'hash_user_8');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Nikolay', 'Iliev', 'nikolay.iliev9@example.com', '+359887930234', 'hash_user_9');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Dimitar', 'Todorov', 'dimitar.todorov10@example.com', '+359888270722', 'hash_user_10');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Anna', 'Marinov', 'anna.marinov11@example.com', '+359884571734', 'hash_user_11');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Victoria', 'Hristov', 'victoria.hristov12@example.com', '+359885247641', 'hash_user_12');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Daniel', 'Yordanov', 'daniel.yordanov13@example.com', '+359886392072', 'hash_user_13');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Martin', 'Vasilev', 'martin.vasilev14@example.com', '+359881329971', 'hash_user_14');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Kristina', 'Angelov', 'kristina.angelov15@example.com', '+359887510968', 'hash_user_15');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Stefan', 'Kostov', 'stefan.kostov16@example.com', '+359887486433', 'hash_user_16');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Petya', 'Kanev', 'petya.kanev17@example.com', '+359887522763', 'hash_user_17');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Rosen', 'Petrova', 'rosen.petrova18@example.com', '+359884228244', 'hash_user_18');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Mariya', 'Ivanova', 'mariya.ivanova19@example.com', '+359884318901', 'hash_user_19');
INSERT INTO `User` (role_ID, userFirstName, userLastName, userEmail, userPhone, userPasswordHash) VALUES (2, 'Kaloyan', 'Dimitrova', 'kaloyan.dimitrova20@example.com', '+359887216600', 'hash_user_20');

-- INSERT RESTAURANTS:
INSERT INTO Restaurant (restaurantName, restaurantDescription, restaurantAddress, restaurantCity, restaurantCountry, restaurantCapacity, restaurantMinPeople, restaurantMaxPeople) VALUES ('Restaurant 1', 'Cozy place number 1.', 'Street 1 No. 21', 'Sofia', 'Bulgaria', 117, 1, 8);
INSERT INTO Restaurant (restaurantName, restaurantDescription, restaurantAddress, restaurantCity, restaurantCountry, restaurantCapacity, restaurantMinPeople, restaurantMaxPeople) VALUES ('Restaurant 2', 'Cozy place number 2.', 'Street 2 No. 13', 'Plovdiv', 'Bulgaria', 114, 1, 8);
INSERT INTO Restaurant (restaurantName, restaurantDescription, restaurantAddress, restaurantCity, restaurantCountry, restaurantCapacity, restaurantMinPeople, restaurantMaxPeople) VALUES ('Restaurant 3', 'Cozy place number 3.', 'Street 3 No. 30', 'Varna', 'Bulgaria', 42, 1, 8);
INSERT INTO Restaurant (restaurantName, restaurantDescription, restaurantAddress, restaurantCity, restaurantCountry, restaurantCapacity, restaurantMinPeople, restaurantMaxPeople) VALUES ('Restaurant 4', 'Cozy place number 4.', 'Street 4 No. 8', 'Burgas', 'Bulgaria', 97, 1, 8);
INSERT INTO Restaurant (restaurantName, restaurantDescription, restaurantAddress, restaurantCity, restaurantCountry, restaurantCapacity, restaurantMinPeople, restaurantMaxPeople) VALUES ('Restaurant 5', 'Cozy place number 5.', 'Street 5 No. 25', 'Ruse', 'Bulgaria', 51, 1, 8);
INSERT INTO Restaurant (restaurantName, restaurantDescription, restaurantAddress, restaurantCity, restaurantCountry, restaurantCapacity, restaurantMinPeople, restaurantMaxPeople) VALUES ('Restaurant 6', 'Cozy place number 6.', 'Street 6 No. 27', 'Sofia', 'Bulgaria', 72, 1, 8);
INSERT INTO Restaurant (restaurantName, restaurantDescription, restaurantAddress, restaurantCity, restaurantCountry, restaurantCapacity, restaurantMinPeople, restaurantMaxPeople) VALUES ('Restaurant 7', 'Cozy place number 7.', 'Street 7 No. 9', 'Plovdiv', 'Bulgaria', 96, 1, 8);
INSERT INTO Restaurant (restaurantName, restaurantDescription, restaurantAddress, restaurantCity, restaurantCountry, restaurantCapacity, restaurantMinPeople, restaurantMaxPeople) VALUES ('Restaurant 8', 'Cozy place number 8.', 'Street 8 No. 19', 'Varna', 'Bulgaria', 56, 1, 8);
INSERT INTO Restaurant (restaurantName, restaurantDescription, restaurantAddress, restaurantCity, restaurantCountry, restaurantCapacity, restaurantMinPeople, restaurantMaxPeople) VALUES ('Restaurant 9', 'Cozy place number 9.', 'Street 9 No. 33', 'Burgas', 'Bulgaria', 106, 1, 8);
INSERT INTO Restaurant (restaurantName, restaurantDescription, restaurantAddress, restaurantCity, restaurantCountry, restaurantCapacity, restaurantMinPeople, restaurantMaxPeople) VALUES ('Restaurant 10', 'Cozy place number 10.', 'Street 10 No. 12', 'Ruse', 'Bulgaria', 119, 1, 8);

-- INSERT RESTAURANT OWNERSHIP:
INSERT INTO RestaurantOwnership (user_ID, restaurant_ID) VALUES (4, 1);
INSERT INTO RestaurantOwnership (user_ID, restaurant_ID) VALUES (4, 2);
INSERT INTO RestaurantOwnership (user_ID, restaurant_ID) VALUES (3, 3);
INSERT INTO RestaurantOwnership (user_ID, restaurant_ID) VALUES (2, 4);
INSERT INTO RestaurantOwnership (user_ID, restaurant_ID) VALUES (4, 5);
INSERT INTO RestaurantOwnership (user_ID, restaurant_ID) VALUES (4, 6);
INSERT INTO RestaurantOwnership (user_ID, restaurant_ID) VALUES (2, 7);
INSERT INTO RestaurantOwnership (user_ID, restaurant_ID) VALUES (2, 8);
INSERT INTO RestaurantOwnership (user_ID, restaurant_ID) VALUES (3, 9);
INSERT INTO RestaurantOwnership (user_ID, restaurant_ID) VALUES (2, 10);

-- INSERT TABLES:
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (1, 1, 3, 7, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (1, 2, 2, 3, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (1, 3, 4, 4, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (1, 4, 3, 7, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (1, 5, 3, 6, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (2, 1, 3, 3, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (2, 2, 3, 4, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (2, 3, 2, 3, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (2, 4, 3, 7, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (2, 5, 3, 5, 'terrace');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (3, 1, 2, 2, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (3, 2, 4, 8, 'terrace');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (3, 3, 3, 4, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (3, 4, 2, 5, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (3, 5, 2, 4, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (4, 1, 2, 6, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (4, 2, 3, 4, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (4, 3, 2, 4, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (4, 4, 4, 5, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (4, 5, 3, 4, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (5, 1, 2, 6, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (5, 2, 3, 5, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (5, 3, 4, 5, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (5, 4, 3, 6, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (5, 5, 3, 3, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (6, 1, 4, 7, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (6, 2, 4, 4, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (6, 3, 4, 7, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (6, 4, 2, 4, 'terrace');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (6, 5, 4, 5, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (7, 1, 4, 5, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (7, 2, 3, 3, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (7, 3, 2, 5, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (7, 4, 3, 3, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (7, 5, 2, 2, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (8, 1, 2, 3, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (8, 2, 3, 7, 'terrace');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (8, 3, 3, 7, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (8, 4, 2, 2, 'terrace');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (8, 5, 4, 8, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (9, 1, 2, 2, 'terrace');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (9, 2, 3, 6, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (9, 3, 4, 8, 'inside');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (9, 4, 3, 4, 'terrace');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (9, 5, 2, 4, 'terrace');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (10, 1, 4, 5, 'terrace');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (10, 2, 4, 8, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (10, 3, 2, 4, 'terrace');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (10, 4, 2, 5, 'garden');
INSERT INTO `Table` (restaurant_ID, tableNumber, tableMinCapacity, tableMaxCapacity, tableLocation) VALUES (10, 5, 3, 3, 'garden');

-- INSERT RESERVATIONS:
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 6, 28, DATE_ADD(NOW(), INTERVAL 14 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 6, 28, DATE_ADD(NOW(), INTERVAL 2 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 1, 1, DATE_ADD(NOW(), INTERVAL 1 DAY), 3, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 3, 12, DATE_ADD(NOW(), INTERVAL 13 DAY), 3, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 10, 48, DATE_ADD(NOW(), INTERVAL 6 DAY), 3, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 3, 13, DATE_ADD(NOW(), INTERVAL 10 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 1, 5, DATE_ADD(NOW(), INTERVAL 11 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 5, 24, DATE_ADD(NOW(), INTERVAL 27 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 4, 19, DATE_ADD(NOW(), INTERVAL 8 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 10, 46, DATE_ADD(NOW(), INTERVAL 6 DAY), 2, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 3, 13, DATE_ADD(NOW(), INTERVAL 12 DAY), 5, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 8, 40, DATE_ADD(NOW(), INTERVAL 15 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 1, 5, DATE_ADD(NOW(), INTERVAL 19 DAY), 2, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 8, 38, DATE_ADD(NOW(), INTERVAL 29 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 6, 28, DATE_ADD(NOW(), INTERVAL 19 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 9, 42, DATE_ADD(NOW(), INTERVAL 10 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 4, 20, DATE_ADD(NOW(), INTERVAL 13 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 8, 36, DATE_ADD(NOW(), INTERVAL 6 DAY), 1, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 8, 40, DATE_ADD(NOW(), INTERVAL 17 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 10, 48, DATE_ADD(NOW(), INTERVAL 13 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 7, 33, DATE_ADD(NOW(), INTERVAL 4 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 1, 2, DATE_ADD(NOW(), INTERVAL 14 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 1, 4, DATE_ADD(NOW(), INTERVAL 4 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 9, 42, DATE_ADD(NOW(), INTERVAL 16 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 5, 25, DATE_ADD(NOW(), INTERVAL 10 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 8, 40, DATE_ADD(NOW(), INTERVAL 27 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 2, 7, DATE_ADD(NOW(), INTERVAL 14 DAY), 3, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 7, 31, DATE_ADD(NOW(), INTERVAL 10 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 6, 27, DATE_ADD(NOW(), INTERVAL 27 DAY), 2, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 9, 43, DATE_ADD(NOW(), INTERVAL 5 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 7, 33, DATE_ADD(NOW(), INTERVAL 5 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 1, 3, DATE_ADD(NOW(), INTERVAL 27 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 8, 40, DATE_ADD(NOW(), INTERVAL 8 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 8, 37, DATE_ADD(NOW(), INTERVAL 23 DAY), 4, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 7, 35, DATE_ADD(NOW(), INTERVAL 10 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 9, 41, DATE_ADD(NOW(), INTERVAL 9 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 4, 19, DATE_ADD(NOW(), INTERVAL 13 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 3, 12, DATE_ADD(NOW(), INTERVAL 9 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 3, 14, DATE_ADD(NOW(), INTERVAL 9 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 8, 40, DATE_ADD(NOW(), INTERVAL 14 DAY), 3, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 2, 8, DATE_ADD(NOW(), INTERVAL 14 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 5, 21, DATE_ADD(NOW(), INTERVAL 9 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 9, 44, DATE_ADD(NOW(), INTERVAL 13 DAY), 3, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 10, 50, DATE_ADD(NOW(), INTERVAL 11 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 8, 36, DATE_ADD(NOW(), INTERVAL 14 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 9, 44, DATE_ADD(NOW(), INTERVAL 17 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 1, 3, DATE_ADD(NOW(), INTERVAL 2 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 8, 38, DATE_ADD(NOW(), INTERVAL 8 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 3, 12, DATE_ADD(NOW(), INTERVAL 7 DAY), 2, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 10, 50, DATE_ADD(NOW(), INTERVAL 8 DAY), 2, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 9, 41, DATE_ADD(NOW(), INTERVAL 12 DAY), 1, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 4, 16, DATE_ADD(NOW(), INTERVAL 20 DAY), 1, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 10, 46, DATE_ADD(NOW(), INTERVAL 29 DAY), 3, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 8, 37, DATE_ADD(NOW(), INTERVAL 11 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 4, 16, DATE_ADD(NOW(), INTERVAL 26 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 6, 30, DATE_ADD(NOW(), INTERVAL 16 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 3, 11, DATE_ADD(NOW(), INTERVAL 4 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 7, 32, DATE_ADD(NOW(), INTERVAL 3 DAY), 3, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 8, 38, DATE_ADD(NOW(), INTERVAL 9 DAY), 6, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 4, 17, DATE_ADD(NOW(), INTERVAL 6 DAY), 1, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 7, 31, DATE_ADD(NOW(), INTERVAL 10 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 1, 5, DATE_ADD(NOW(), INTERVAL 11 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 6, 26, DATE_ADD(NOW(), INTERVAL 27 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 7, 31, DATE_ADD(NOW(), INTERVAL 3 DAY), 3, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 1, 2, DATE_ADD(NOW(), INTERVAL 23 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 5, 25, DATE_ADD(NOW(), INTERVAL 29 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 3, 11, DATE_ADD(NOW(), INTERVAL 27 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 9, 42, DATE_ADD(NOW(), INTERVAL 6 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 5, 21, DATE_ADD(NOW(), INTERVAL 1 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 8, 37, DATE_ADD(NOW(), INTERVAL 10 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 3, 13, DATE_ADD(NOW(), INTERVAL 2 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 1, 1, DATE_ADD(NOW(), INTERVAL 24 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 1, 2, DATE_ADD(NOW(), INTERVAL 23 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 9, 43, DATE_ADD(NOW(), INTERVAL 22 DAY), 5, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 7, 34, DATE_ADD(NOW(), INTERVAL 26 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 4, 16, DATE_ADD(NOW(), INTERVAL 12 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 8, 36, DATE_ADD(NOW(), INTERVAL 25 DAY), 2, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 7, 35, DATE_ADD(NOW(), INTERVAL 18 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 3, 15, DATE_ADD(NOW(), INTERVAL 19 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 4, 19, DATE_ADD(NOW(), INTERVAL 2 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 6, 26, DATE_ADD(NOW(), INTERVAL 29 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 9, 45, DATE_ADD(NOW(), INTERVAL 22 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 6, 28, DATE_ADD(NOW(), INTERVAL 22 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 5, 24, DATE_ADD(NOW(), INTERVAL 3 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 6, 26, DATE_ADD(NOW(), INTERVAL 22 DAY), 4, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 9, 42, DATE_ADD(NOW(), INTERVAL 1 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 5, 25, DATE_ADD(NOW(), INTERVAL 28 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 10, 48, DATE_ADD(NOW(), INTERVAL 28 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 7, 34, DATE_ADD(NOW(), INTERVAL 2 DAY), 1, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 3, 12, DATE_ADD(NOW(), INTERVAL 29 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 9, 42, DATE_ADD(NOW(), INTERVAL 8 DAY), 1, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 8, 40, DATE_ADD(NOW(), INTERVAL 9 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 8, 38, DATE_ADD(NOW(), INTERVAL 20 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 2, 8, DATE_ADD(NOW(), INTERVAL 25 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 5, 25, DATE_ADD(NOW(), INTERVAL 29 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 4, 18, DATE_ADD(NOW(), INTERVAL 22 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 1, 2, DATE_ADD(NOW(), INTERVAL 6 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 5, 25, DATE_ADD(NOW(), INTERVAL 1 DAY), 6, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 2, 6, DATE_ADD(NOW(), INTERVAL 23 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 1, 4, DATE_ADD(NOW(), INTERVAL 27 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 6, 29, DATE_ADD(NOW(), INTERVAL 15 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 8, 39, DATE_ADD(NOW(), INTERVAL 27 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 10, 47, DATE_ADD(NOW(), INTERVAL 5 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 6, 26, DATE_ADD(NOW(), INTERVAL 6 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 7, 32, DATE_ADD(NOW(), INTERVAL 22 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 5, 21, DATE_ADD(NOW(), INTERVAL 22 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 10, 46, DATE_ADD(NOW(), INTERVAL 25 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 10, 48, DATE_ADD(NOW(), INTERVAL 22 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 4, 19, DATE_ADD(NOW(), INTERVAL 10 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 1, 2, DATE_ADD(NOW(), INTERVAL 25 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 8, 37, DATE_ADD(NOW(), INTERVAL 21 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 3, 12, DATE_ADD(NOW(), INTERVAL 4 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 6, 29, DATE_ADD(NOW(), INTERVAL 4 DAY), 3, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 5, 21, DATE_ADD(NOW(), INTERVAL 10 DAY), 1, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 4, 19, DATE_ADD(NOW(), INTERVAL 22 DAY), 1, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 3, 11, DATE_ADD(NOW(), INTERVAL 6 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 7, 35, DATE_ADD(NOW(), INTERVAL 13 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 2, 9, DATE_ADD(NOW(), INTERVAL 14 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 8, 40, DATE_ADD(NOW(), INTERVAL 22 DAY), 1, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 7, 34, DATE_ADD(NOW(), INTERVAL 26 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 9, 44, DATE_ADD(NOW(), INTERVAL 7 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 10, 47, DATE_ADD(NOW(), INTERVAL 22 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 8, 40, DATE_ADD(NOW(), INTERVAL 14 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 7, 32, DATE_ADD(NOW(), INTERVAL 6 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 5, 25, DATE_ADD(NOW(), INTERVAL 19 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 7, 35, DATE_ADD(NOW(), INTERVAL 21 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 8, 40, DATE_ADD(NOW(), INTERVAL 25 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 6, 30, DATE_ADD(NOW(), INTERVAL 9 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 5, 24, DATE_ADD(NOW(), INTERVAL 7 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 8, 37, DATE_ADD(NOW(), INTERVAL 27 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 1, 2, DATE_ADD(NOW(), INTERVAL 7 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 7, 31, DATE_ADD(NOW(), INTERVAL 11 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 2, 8, DATE_ADD(NOW(), INTERVAL 27 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 4, 20, DATE_ADD(NOW(), INTERVAL 21 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 7, 31, DATE_ADD(NOW(), INTERVAL 14 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 6, 28, DATE_ADD(NOW(), INTERVAL 10 DAY), 3, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 8, 40, DATE_ADD(NOW(), INTERVAL 18 DAY), 1, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 2, 6, DATE_ADD(NOW(), INTERVAL 10 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 4, 20, DATE_ADD(NOW(), INTERVAL 6 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 1, 3, DATE_ADD(NOW(), INTERVAL 2 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 9, 44, DATE_ADD(NOW(), INTERVAL 5 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 1, 3, DATE_ADD(NOW(), INTERVAL 20 DAY), 6, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 9, 45, DATE_ADD(NOW(), INTERVAL 7 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 9, 45, DATE_ADD(NOW(), INTERVAL 21 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 1, 4, DATE_ADD(NOW(), INTERVAL 23 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 8, 40, DATE_ADD(NOW(), INTERVAL 2 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 5, 24, DATE_ADD(NOW(), INTERVAL 27 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 6, 30, DATE_ADD(NOW(), INTERVAL 10 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 10, 48, DATE_ADD(NOW(), INTERVAL 22 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 10, 47, DATE_ADD(NOW(), INTERVAL 19 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 5, 23, DATE_ADD(NOW(), INTERVAL 13 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 9, 45, DATE_ADD(NOW(), INTERVAL 26 DAY), 6, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 9, 41, DATE_ADD(NOW(), INTERVAL 29 DAY), 6, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 1, 5, DATE_ADD(NOW(), INTERVAL 12 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 10, 46, DATE_ADD(NOW(), INTERVAL 10 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 2, 10, DATE_ADD(NOW(), INTERVAL 14 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 8, 38, DATE_ADD(NOW(), INTERVAL 15 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 3, 12, DATE_ADD(NOW(), INTERVAL 18 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 3, 14, DATE_ADD(NOW(), INTERVAL 12 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 2, 7, DATE_ADD(NOW(), INTERVAL 5 DAY), 3, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 7, 32, DATE_ADD(NOW(), INTERVAL 19 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 9, 42, DATE_ADD(NOW(), INTERVAL 19 DAY), 2, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 2, 8, DATE_ADD(NOW(), INTERVAL 19 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 10, 47, DATE_ADD(NOW(), INTERVAL 17 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 1, 4, DATE_ADD(NOW(), INTERVAL 4 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 8, 37, DATE_ADD(NOW(), INTERVAL 8 DAY), 1, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 5, 21, DATE_ADD(NOW(), INTERVAL 19 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 9, 43, DATE_ADD(NOW(), INTERVAL 20 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 8, 37, DATE_ADD(NOW(), INTERVAL 25 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 8, 39, DATE_ADD(NOW(), INTERVAL 22 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 2, 10, DATE_ADD(NOW(), INTERVAL 16 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 5, 23, DATE_ADD(NOW(), INTERVAL 17 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 1, 3, DATE_ADD(NOW(), INTERVAL 1 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 2, 8, DATE_ADD(NOW(), INTERVAL 21 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 10, 49, DATE_ADD(NOW(), INTERVAL 14 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 7, 33, DATE_ADD(NOW(), INTERVAL 26 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 5, 25, DATE_ADD(NOW(), INTERVAL 24 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 5, 25, DATE_ADD(NOW(), INTERVAL 7 DAY), 5, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 7, 33, DATE_ADD(NOW(), INTERVAL 8 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 1, 5, DATE_ADD(NOW(), INTERVAL 1 DAY), 6, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 4, 16, DATE_ADD(NOW(), INTERVAL 6 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 1, 5, DATE_ADD(NOW(), INTERVAL 1 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 1, 5, DATE_ADD(NOW(), INTERVAL 22 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 8, 36, DATE_ADD(NOW(), INTERVAL 25 DAY), 5, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 1, 3, DATE_ADD(NOW(), INTERVAL 14 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 1, 5, DATE_ADD(NOW(), INTERVAL 20 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 4, 16, DATE_ADD(NOW(), INTERVAL 8 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 1, 3, DATE_ADD(NOW(), INTERVAL 16 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 6, 29, DATE_ADD(NOW(), INTERVAL 13 DAY), 1, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 1, 5, DATE_ADD(NOW(), INTERVAL 7 DAY), 5, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 5, 22, DATE_ADD(NOW(), INTERVAL 5 DAY), 5, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 5, 21, DATE_ADD(NOW(), INTERVAL 22 DAY), 4, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 8, 39, DATE_ADD(NOW(), INTERVAL 28 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 5, 25, DATE_ADD(NOW(), INTERVAL 26 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 3, 11, DATE_ADD(NOW(), INTERVAL 16 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 5, 22, DATE_ADD(NOW(), INTERVAL 17 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 1, 1, DATE_ADD(NOW(), INTERVAL 23 DAY), 5, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 5, 23, DATE_ADD(NOW(), INTERVAL 10 DAY), 4, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 9, 44, DATE_ADD(NOW(), INTERVAL 7 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 7, 34, DATE_ADD(NOW(), INTERVAL 19 DAY), 5, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 10, 48, DATE_ADD(NOW(), INTERVAL 26 DAY), 6, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 8, 36, DATE_ADD(NOW(), INTERVAL 2 DAY), 4, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 10, 47, DATE_ADD(NOW(), INTERVAL 25 DAY), 1, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 7, 33, DATE_ADD(NOW(), INTERVAL 28 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 7, 34, DATE_ADD(NOW(), INTERVAL 1 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 7, 32, DATE_ADD(NOW(), INTERVAL 20 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 1, 5, DATE_ADD(NOW(), INTERVAL 13 DAY), 2, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 10, 50, DATE_ADD(NOW(), INTERVAL 29 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 8, 39, DATE_ADD(NOW(), INTERVAL 19 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 9, 43, DATE_ADD(NOW(), INTERVAL 25 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 8, 36, DATE_ADD(NOW(), INTERVAL 10 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 10, 50, DATE_ADD(NOW(), INTERVAL 27 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 5, 24, DATE_ADD(NOW(), INTERVAL 11 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 3, 15, DATE_ADD(NOW(), INTERVAL 1 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 3, 12, DATE_ADD(NOW(), INTERVAL 24 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 1, 1, DATE_ADD(NOW(), INTERVAL 21 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 2, 9, DATE_ADD(NOW(), INTERVAL 28 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 9, 45, DATE_ADD(NOW(), INTERVAL 3 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 7, 35, DATE_ADD(NOW(), INTERVAL 11 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 6, 27, DATE_ADD(NOW(), INTERVAL 8 DAY), 4, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 7, 33, DATE_ADD(NOW(), INTERVAL 2 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 10, 50, DATE_ADD(NOW(), INTERVAL 27 DAY), 5, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 9, 45, DATE_ADD(NOW(), INTERVAL 26 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 5, 21, DATE_ADD(NOW(), INTERVAL 12 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 2, 8, DATE_ADD(NOW(), INTERVAL 29 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 5, 24, DATE_ADD(NOW(), INTERVAL 28 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 2, 10, DATE_ADD(NOW(), INTERVAL 19 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 7, 35, DATE_ADD(NOW(), INTERVAL 10 DAY), 4, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 4, 18, DATE_ADD(NOW(), INTERVAL 21 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 5, 22, DATE_ADD(NOW(), INTERVAL 12 DAY), 2, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 4, 19, DATE_ADD(NOW(), INTERVAL 1 DAY), 2, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 2, 8, DATE_ADD(NOW(), INTERVAL 5 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 4, 17, DATE_ADD(NOW(), INTERVAL 21 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 2, 6, DATE_ADD(NOW(), INTERVAL 10 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 8, 38, DATE_ADD(NOW(), INTERVAL 10 DAY), 5, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 3, 14, DATE_ADD(NOW(), INTERVAL 13 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 3, 14, DATE_ADD(NOW(), INTERVAL 10 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 8, 37, DATE_ADD(NOW(), INTERVAL 6 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 8, 40, DATE_ADD(NOW(), INTERVAL 21 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 9, 43, DATE_ADD(NOW(), INTERVAL 12 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 10, 48, DATE_ADD(NOW(), INTERVAL 13 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 5, 24, DATE_ADD(NOW(), INTERVAL 22 DAY), 1, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 4, 19, DATE_ADD(NOW(), INTERVAL 16 DAY), 3, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 3, 14, DATE_ADD(NOW(), INTERVAL 25 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 9, 41, DATE_ADD(NOW(), INTERVAL 8 DAY), 4, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 6, 28, DATE_ADD(NOW(), INTERVAL 27 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 4, 19, DATE_ADD(NOW(), INTERVAL 27 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 9, 44, DATE_ADD(NOW(), INTERVAL 16 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 6, 26, DATE_ADD(NOW(), INTERVAL 11 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 8, 40, DATE_ADD(NOW(), INTERVAL 29 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 7, 34, DATE_ADD(NOW(), INTERVAL 3 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 10, 46, DATE_ADD(NOW(), INTERVAL 28 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 2, 10, DATE_ADD(NOW(), INTERVAL 23 DAY), 3, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 10, 48, DATE_ADD(NOW(), INTERVAL 1 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 5, 25, DATE_ADD(NOW(), INTERVAL 4 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 1, 2, DATE_ADD(NOW(), INTERVAL 26 DAY), 4, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 2, 10, DATE_ADD(NOW(), INTERVAL 22 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 1, 4, DATE_ADD(NOW(), INTERVAL 4 DAY), 3, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 8, 38, DATE_ADD(NOW(), INTERVAL 21 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 10, 49, DATE_ADD(NOW(), INTERVAL 12 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 6, 28, DATE_ADD(NOW(), INTERVAL 26 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 8, 40, DATE_ADD(NOW(), INTERVAL 15 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 9, 41, DATE_ADD(NOW(), INTERVAL 21 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 5, 25, DATE_ADD(NOW(), INTERVAL 29 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 9, 45, DATE_ADD(NOW(), INTERVAL 5 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 8, 38, DATE_ADD(NOW(), INTERVAL 25 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 5, 21, DATE_ADD(NOW(), INTERVAL 17 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 5, 25, DATE_ADD(NOW(), INTERVAL 18 DAY), 6, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 2, 9, DATE_ADD(NOW(), INTERVAL 11 DAY), 3, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 2, 9, DATE_ADD(NOW(), INTERVAL 29 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 5, 25, DATE_ADD(NOW(), INTERVAL 21 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 5, 21, DATE_ADD(NOW(), INTERVAL 27 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 4, 16, DATE_ADD(NOW(), INTERVAL 26 DAY), 3, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 4, 17, DATE_ADD(NOW(), INTERVAL 13 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 10, 47, DATE_ADD(NOW(), INTERVAL 27 DAY), 1, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 6, 30, DATE_ADD(NOW(), INTERVAL 19 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 1, 5, DATE_ADD(NOW(), INTERVAL 13 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 3, 15, DATE_ADD(NOW(), INTERVAL 13 DAY), 3, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 5, 23, DATE_ADD(NOW(), INTERVAL 22 DAY), 5, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 6, 30, DATE_ADD(NOW(), INTERVAL 28 DAY), 1, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 6, 28, DATE_ADD(NOW(), INTERVAL 7 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 2, 10, DATE_ADD(NOW(), INTERVAL 23 DAY), 3, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 3, 15, DATE_ADD(NOW(), INTERVAL 17 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 7, 31, DATE_ADD(NOW(), INTERVAL 26 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 8, 40, DATE_ADD(NOW(), INTERVAL 19 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 7, 32, DATE_ADD(NOW(), INTERVAL 28 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 4, 16, DATE_ADD(NOW(), INTERVAL 25 DAY), 1, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 1, 3, DATE_ADD(NOW(), INTERVAL 14 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 5, 23, DATE_ADD(NOW(), INTERVAL 23 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 1, 4, DATE_ADD(NOW(), INTERVAL 19 DAY), 5, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (14, 10, 48, DATE_ADD(NOW(), INTERVAL 23 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 1, 2, DATE_ADD(NOW(), INTERVAL 17 DAY), 2, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 5, 24, DATE_ADD(NOW(), INTERVAL 25 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 10, 49, DATE_ADD(NOW(), INTERVAL 12 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 3, 11, DATE_ADD(NOW(), INTERVAL 19 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 7, 33, DATE_ADD(NOW(), INTERVAL 20 DAY), 4, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 4, 16, DATE_ADD(NOW(), INTERVAL 20 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 8, 40, DATE_ADD(NOW(), INTERVAL 20 DAY), 6, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 1, 2, DATE_ADD(NOW(), INTERVAL 25 DAY), 6, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 6, 30, DATE_ADD(NOW(), INTERVAL 20 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 5, 25, DATE_ADD(NOW(), INTERVAL 11 DAY), 2, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 3, 12, DATE_ADD(NOW(), INTERVAL 19 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 5, 24, DATE_ADD(NOW(), INTERVAL 27 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 7, 31, DATE_ADD(NOW(), INTERVAL 1 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 2, 10, DATE_ADD(NOW(), INTERVAL 6 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 6, 30, DATE_ADD(NOW(), INTERVAL 12 DAY), 3, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 3, 12, DATE_ADD(NOW(), INTERVAL 20 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 7, 33, DATE_ADD(NOW(), INTERVAL 15 DAY), 3, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 1, 4, DATE_ADD(NOW(), INTERVAL 27 DAY), 1, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 10, 48, DATE_ADD(NOW(), INTERVAL 26 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 1, 3, DATE_ADD(NOW(), INTERVAL 23 DAY), 1, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 10, 48, DATE_ADD(NOW(), INTERVAL 17 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 7, 32, DATE_ADD(NOW(), INTERVAL 2 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 10, 48, DATE_ADD(NOW(), INTERVAL 19 DAY), 2, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 4, 17, DATE_ADD(NOW(), INTERVAL 8 DAY), 6, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 2, 7, DATE_ADD(NOW(), INTERVAL 4 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 1, 3, DATE_ADD(NOW(), INTERVAL 19 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 4, 16, DATE_ADD(NOW(), INTERVAL 16 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 10, 48, DATE_ADD(NOW(), INTERVAL 4 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 4, 16, DATE_ADD(NOW(), INTERVAL 11 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 7, 35, DATE_ADD(NOW(), INTERVAL 3 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 4, 16, DATE_ADD(NOW(), INTERVAL 7 DAY), 3, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 5, 23, DATE_ADD(NOW(), INTERVAL 22 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 10, 48, DATE_ADD(NOW(), INTERVAL 14 DAY), 1, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 6, 29, DATE_ADD(NOW(), INTERVAL 29 DAY), 6, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 10, 50, DATE_ADD(NOW(), INTERVAL 12 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 2, 8, DATE_ADD(NOW(), INTERVAL 28 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 2, 8, DATE_ADD(NOW(), INTERVAL 6 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 6, 30, DATE_ADD(NOW(), INTERVAL 3 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 1, 2, DATE_ADD(NOW(), INTERVAL 26 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 2, 8, DATE_ADD(NOW(), INTERVAL 16 DAY), 3, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 10, 46, DATE_ADD(NOW(), INTERVAL 11 DAY), 1, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 7, 31, DATE_ADD(NOW(), INTERVAL 7 DAY), 5, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 6, 30, DATE_ADD(NOW(), INTERVAL 15 DAY), 3, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 1, 3, DATE_ADD(NOW(), INTERVAL 20 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 8, 38, DATE_ADD(NOW(), INTERVAL 22 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 8, 40, DATE_ADD(NOW(), INTERVAL 13 DAY), 2, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 1, 5, DATE_ADD(NOW(), INTERVAL 29 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 3, 15, DATE_ADD(NOW(), INTERVAL 1 DAY), 1, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 9, 43, DATE_ADD(NOW(), INTERVAL 1 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 2, 9, DATE_ADD(NOW(), INTERVAL 9 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 1, 4, DATE_ADD(NOW(), INTERVAL 26 DAY), 3, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 8, 36, DATE_ADD(NOW(), INTERVAL 4 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 1, 1, DATE_ADD(NOW(), INTERVAL 20 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 8, 38, DATE_ADD(NOW(), INTERVAL 7 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 9, 42, DATE_ADD(NOW(), INTERVAL 4 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 1, 1, DATE_ADD(NOW(), INTERVAL 12 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 2, 6, DATE_ADD(NOW(), INTERVAL 13 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 7, 33, DATE_ADD(NOW(), INTERVAL 27 DAY), 4, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 4, 18, DATE_ADD(NOW(), INTERVAL 3 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (17, 7, 31, DATE_ADD(NOW(), INTERVAL 7 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 8, 37, DATE_ADD(NOW(), INTERVAL 10 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 3, 11, DATE_ADD(NOW(), INTERVAL 3 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 10, 47, DATE_ADD(NOW(), INTERVAL 15 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 5, 24, DATE_ADD(NOW(), INTERVAL 5 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 10, 49, DATE_ADD(NOW(), INTERVAL 1 DAY), 4, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 6, 30, DATE_ADD(NOW(), INTERVAL 7 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 10, 49, DATE_ADD(NOW(), INTERVAL 8 DAY), 6, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 7, 33, DATE_ADD(NOW(), INTERVAL 26 DAY), 5, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 7, 32, DATE_ADD(NOW(), INTERVAL 3 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 5, 25, DATE_ADD(NOW(), INTERVAL 12 DAY), 5, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 1, 3, DATE_ADD(NOW(), INTERVAL 16 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 4, 17, DATE_ADD(NOW(), INTERVAL 16 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 9, 44, DATE_ADD(NOW(), INTERVAL 17 DAY), 3, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 10, 47, DATE_ADD(NOW(), INTERVAL 22 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 9, 45, DATE_ADD(NOW(), INTERVAL 11 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 7, 32, DATE_ADD(NOW(), INTERVAL 28 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 9, 43, DATE_ADD(NOW(), INTERVAL 2 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 5, 25, DATE_ADD(NOW(), INTERVAL 16 DAY), 4, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 7, 34, DATE_ADD(NOW(), INTERVAL 5 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 10, 47, DATE_ADD(NOW(), INTERVAL 3 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 4, 19, DATE_ADD(NOW(), INTERVAL 27 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 6, 28, DATE_ADD(NOW(), INTERVAL 26 DAY), 3, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (19, 1, 5, DATE_ADD(NOW(), INTERVAL 12 DAY), 2, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 4, 16, DATE_ADD(NOW(), INTERVAL 9 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (13, 3, 15, DATE_ADD(NOW(), INTERVAL 24 DAY), 5, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 10, 47, DATE_ADD(NOW(), INTERVAL 3 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 9, 41, DATE_ADD(NOW(), INTERVAL 8 DAY), 4, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (8, 10, 46, DATE_ADD(NOW(), INTERVAL 23 DAY), 4, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 10, 50, DATE_ADD(NOW(), INTERVAL 3 DAY), 1, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 2, 9, DATE_ADD(NOW(), INTERVAL 25 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 1, 3, DATE_ADD(NOW(), INTERVAL 7 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (18, 4, 17, DATE_ADD(NOW(), INTERVAL 24 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 4, 19, DATE_ADD(NOW(), INTERVAL 9 DAY), 5, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 7, 35, DATE_ADD(NOW(), INTERVAL 28 DAY), 5, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 3, 15, DATE_ADD(NOW(), INTERVAL 24 DAY), 2, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 6, 29, DATE_ADD(NOW(), INTERVAL 21 DAY), 6, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (6, 7, 35, DATE_ADD(NOW(), INTERVAL 22 DAY), 5, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (15, 6, 30, DATE_ADD(NOW(), INTERVAL 17 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 9, 44, DATE_ADD(NOW(), INTERVAL 12 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (5, 7, 32, DATE_ADD(NOW(), INTERVAL 25 DAY), 3, 'NoShow');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (7, 3, 13, DATE_ADD(NOW(), INTERVAL 3 DAY), 6, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 4, 16, DATE_ADD(NOW(), INTERVAL 11 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 7, 35, DATE_ADD(NOW(), INTERVAL 10 DAY), 3, 'Cancelled');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (12, 10, 47, DATE_ADD(NOW(), INTERVAL 25 DAY), 1, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (20, 10, 47, DATE_ADD(NOW(), INTERVAL 26 DAY), 6, 'Pending');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (10, 8, 39, DATE_ADD(NOW(), INTERVAL 6 DAY), 4, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (9, 6, 29, DATE_ADD(NOW(), INTERVAL 26 DAY), 5, 'Completed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (16, 8, 40, DATE_ADD(NOW(), INTERVAL 26 DAY), 4, 'Confirmed');
INSERT INTO Reservation (user_ID, restaurant_ID, table_ID, reservationDateTime, reservationGuestCount, reservationStatus) VALUES (11, 8, 38, DATE_ADD(NOW(), INTERVAL 23 DAY), 1, 'Completed');

-- INSERT REVIEWS:
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (381, 14, 9, 1, 'Auto-generated review #1', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (225, 16, 5, 5, 'Auto-generated review #2', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (165, 16, 9, 2, 'Auto-generated review #3', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (327, 11, 2, 3, 'Auto-generated review #4', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (140, 12, 7, 4, 'Auto-generated review #5', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (52, 14, 3, 1, 'Auto-generated review #6', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (352, 13, 2, 3, 'Auto-generated review #7', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (34, 10, 9, 2, 'Auto-generated review #8', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (58, 11, 9, 2, 'Auto-generated review #9', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (194, 10, 9, 3, 'Auto-generated review #10', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (318, 5, 4, 3, 'Auto-generated review #11', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (57, 8, 7, 4, 'Auto-generated review #12', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (98, 18, 1, 5, 'Auto-generated review #13', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (48, 15, 1, 5, 'Auto-generated review #14', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (108, 5, 8, 5, 'Auto-generated review #15', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (321, 17, 7, 1, 'Auto-generated review #16', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (210, 10, 9, 3, 'Auto-generated review #17', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (136, 18, 5, 4, 'Auto-generated review #18', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (183, 9, 9, 5, 'Auto-generated review #19', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (96, 16, 1, 2, 'Auto-generated review #20', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (258, 15, 5, 5, 'Auto-generated review #21', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (65, 7, 8, 2, 'Auto-generated review #22', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (238, 13, 4, 4, 'Auto-generated review #23', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (269, 20, 5, 1, 'Auto-generated review #24', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (383, 8, 1, 2, 'Auto-generated review #25', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (340, 8, 2, 5, 'Auto-generated review #26', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (26, 17, 6, 4, 'Auto-generated review #27', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (277, 20, 10, 4, 'Auto-generated review #28', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (91, 16, 9, 5, 'Auto-generated review #29', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (357, 19, 1, 4, 'Auto-generated review #30', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (156, 16, 5, 2, 'Auto-generated review #31', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (227, 5, 6, 3, 'Auto-generated review #32', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (387, 17, 1, 1, 'Auto-generated review #33', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (54, 14, 8, 4, 'Auto-generated review #34', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (384, 7, 7, 1, 'Auto-generated review #35', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (51, 19, 3, 3, 'Auto-generated review #36', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (270, 10, 2, 1, 'Auto-generated review #37', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (200, 20, 3, 2, 'Auto-generated review #38', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (17, 19, 8, 2, 'Auto-generated review #39', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (305, 18, 2, 4, 'Auto-generated review #40', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (303, 9, 5, 3, 'Auto-generated review #41', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (233, 11, 6, 5, 'Auto-generated review #42', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (377, 13, 9, 1, 'Auto-generated review #43', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (335, 12, 5, 2, 'Auto-generated review #44', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (126, 10, 3, 2, 'Auto-generated review #45', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (254, 14, 4, 4, 'Auto-generated review #46', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (248, 20, 8, 5, 'Auto-generated review #47', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (380, 20, 6, 4, 'Auto-generated review #48', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (46, 16, 5, 1, 'Auto-generated review #49', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (390, 11, 2, 3, 'Auto-generated review #50', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (110, 7, 4, 1, 'Auto-generated review #51', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (369, 16, 5, 3, 'Auto-generated review #52', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (33, 11, 7, 4, 'Auto-generated review #53', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (293, 7, 7, 2, 'Auto-generated review #54', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (82, 14, 9, 3, 'Auto-generated review #55', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (336, 13, 5, 1, 'Auto-generated review #56', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (359, 20, 10, 4, 'Auto-generated review #57', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (358, 19, 6, 3, 'Auto-generated review #58', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (288, 13, 8, 2, 'Auto-generated review #59', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (388, 9, 6, 2, 'Auto-generated review #60', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (243, 11, 10, 2, 'Auto-generated review #61', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (150, 20, 3, 3, 'Auto-generated review #62', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (309, 19, 5, 1, 'Auto-generated review #63', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (399, 6, 9, 5, 'Auto-generated review #64', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (276, 19, 8, 3, 'Auto-generated review #65', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (281, 19, 4, 1, 'Auto-generated review #66', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (297, 11, 6, 1, 'Auto-generated review #67', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (124, 14, 3, 5, 'Auto-generated review #68', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (70, 18, 4, 1, 'Auto-generated review #69', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (50, 10, 8, 1, 'Auto-generated review #70', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (45, 19, 1, 5, 'Auto-generated review #71', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (28, 7, 8, 3, 'Auto-generated review #72', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (137, 10, 3, 5, 'Auto-generated review #73', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (260, 6, 8, 2, 'Auto-generated review #74', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (169, 12, 8, 4, 'Auto-generated review #75', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (56, 18, 3, 4, 'Auto-generated review #76', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (197, 8, 6, 4, 'Auto-generated review #77', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (385, 9, 2, 1, 'Auto-generated review #78', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (88, 11, 4, 4, 'Auto-generated review #79', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (363, 11, 10, 2, 'Auto-generated review #80', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (222, 11, 4, 2, 'Auto-generated review #81', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (355, 19, 6, 5, 'Auto-generated review #82', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (76, 11, 10, 1, 'Auto-generated review #83', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (189, 7, 1, 3, 'Auto-generated review #84', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (219, 7, 2, 3, 'Auto-generated review #85', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (279, 18, 7, 2, 'Auto-generated review #86', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (185, 5, 4, 3, 'Auto-generated review #87', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (368, 10, 7, 4, 'Auto-generated review #88', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (215, 16, 7, 3, 'Auto-generated review #89', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (86, 19, 1, 2, 'Auto-generated review #90', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (68, 6, 10, 5, 'Auto-generated review #91', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (16, 7, 2, 3, 'Auto-generated review #92', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (298, 19, 6, 2, 'Auto-generated review #93', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (313, 10, 5, 3, 'Auto-generated review #94', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (312, 7, 7, 3, 'Auto-generated review #95', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (3, 13, 7, 2, 'Auto-generated review #96', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (231, 11, 5, 5, 'Auto-generated review #97', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (187, 5, 8, 5, 'Auto-generated review #98', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (182, 16, 4, 5, 'Auto-generated review #99', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (324, 11, 6, 5, 'Auto-generated review #100', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (300, 9, 1, 2, 'Auto-generated review #101', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (192, 18, 7, 3, 'Auto-generated review #102', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (83, 14, 8, 3, 'Auto-generated review #103', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (60, 14, 9, 2, 'Auto-generated review #104', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (186, 8, 2, 1, 'Auto-generated review #105', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (212, 8, 5, 1, 'Auto-generated review #106', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (286, 7, 8, 1, 'Auto-generated review #107', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (160, 15, 5, 3, 'Auto-generated review #108', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (284, 8, 9, 3, 'Auto-generated review #109', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (18, 15, 5, 4, 'Auto-generated review #110', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (199, 6, 3, 1, 'Auto-generated review #111', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (120, 8, 4, 3, 'Auto-generated review #112', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (90, 12, 5, 2, 'Auto-generated review #113', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (107, 14, 8, 3, 'Auto-generated review #114', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (360, 19, 6, 4, 'Auto-generated review #115', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (344, 16, 1, 4, 'Auto-generated review #116', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (356, 5, 10, 1, 'Auto-generated review #117', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (155, 7, 4, 1, 'Auto-generated review #118', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (24, 15, 8, 1, 'Auto-generated review #119', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (127, 18, 8, 1, 'Auto-generated review #120', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (144, 17, 2, 1, 'Auto-generated review #121', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (235, 11, 3, 3, 'Auto-generated review #122', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (149, 11, 2, 5, 'Auto-generated review #123', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (307, 11, 3, 1, 'Auto-generated review #124', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (118, 12, 7, 1, 'Auto-generated review #125', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (341, 5, 7, 2, 'Auto-generated review #126', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (132, 14, 4, 3, 'Auto-generated review #127', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (240, 19, 8, 3, 'Auto-generated review #128', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (289, 8, 8, 1, 'Auto-generated review #129', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (19, 20, 2, 5, 'Auto-generated review #130', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (237, 16, 8, 5, 'Auto-generated review #131', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (266, 7, 1, 3, 'Auto-generated review #132', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (67, 14, 9, 4, 'Auto-generated review #133', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (157, 16, 8, 1, 'Auto-generated review #134', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (331, 18, 3, 2, 'Auto-generated review #135', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (328, 5, 6, 1, 'Auto-generated review #136', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (319, 17, 3, 5, 'Auto-generated review #137', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (75, 11, 1, 4, 'Auto-generated review #138', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (190, 15, 5, 5, 'Auto-generated review #139', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (217, 20, 4, 1, 'Auto-generated review #140', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (257, 20, 10, 1, 'Auto-generated review #141', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (117, 14, 7, 3, 'Auto-generated review #142', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (252, 14, 1, 4, 'Auto-generated review #143', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (128, 17, 3, 2, 'Auto-generated review #144', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (72, 7, 8, 1, 'Auto-generated review #145', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (392, 16, 3, 4, 'Auto-generated review #146', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (102, 17, 10, 3, 'Auto-generated review #147', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (391, 14, 3, 1, 'Auto-generated review #148', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (351, 10, 4, 4, 'Auto-generated review #149', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (167, 11, 2, 1, 'Auto-generated review #150', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (93, 17, 1, 2, 'Auto-generated review #151', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (244, 19, 2, 4, 'Auto-generated review #152', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (148, 17, 10, 2, 'Auto-generated review #153', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (113, 18, 3, 1, 'Auto-generated review #154', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (314, 18, 2, 2, 'Auto-generated review #155', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (100, 12, 8, 4, 'Auto-generated review #156', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (361, 11, 4, 1, 'Auto-generated review #157', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (287, 13, 9, 5, 'Auto-generated review #158', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (326, 10, 6, 4, 'Auto-generated review #159', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (151, 13, 1, 3, 'Auto-generated review #160', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (221, 13, 6, 1, 'Auto-generated review #161', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (193, 11, 7, 3, 'Auto-generated review #162', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (262, 5, 9, 3, 'Auto-generated review #163', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (31, 14, 6, 3, 'Auto-generated review #164', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (71, 10, 7, 5, 'Auto-generated review #165', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (74, 7, 9, 2, 'Auto-generated review #166', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (195, 20, 2, 4, 'Auto-generated review #167', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (181, 13, 6, 2, 'Auto-generated review #168', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (373, 12, 9, 5, 'Auto-generated review #169', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (97, 8, 9, 3, 'Auto-generated review #170', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (141, 9, 8, 3, 'Auto-generated review #171', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (73, 5, 3, 5, 'Auto-generated review #172', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (14, 10, 3, 2, 'Auto-generated review #173', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (301, 8, 5, 4, 'Auto-generated review #174', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (213, 20, 2, 3, 'Auto-generated review #175', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (295, 6, 8, 3, 'Auto-generated review #176', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (214, 12, 3, 2, 'Auto-generated review #177', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (99, 5, 1, 1, 'Auto-generated review #178', DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (274, 17, 7, 1, 'Auto-generated review #179', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (129, 7, 10, 5, 'Auto-generated review #180', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (263, 19, 7, 4, 'Auto-generated review #181', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (246, 6, 8, 3, 'Auto-generated review #182', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (15, 13, 9, 1, 'Auto-generated review #183', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (311, 13, 7, 5, 'Auto-generated review #184', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (291, 6, 4, 4, 'Auto-generated review #185', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (230, 13, 8, 1, 'Auto-generated review #186', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (229, 18, 7, 3, 'Auto-generated review #187', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (350, 5, 7, 2, 'Auto-generated review #188', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (337, 17, 1, 5, 'Auto-generated review #189', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (11, 15, 4, 2, 'Auto-generated review #190', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (179, 8, 10, 4, 'Auto-generated review #191', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (173, 12, 5, 3, 'Auto-generated review #192', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (208, 11, 3, 5, 'Auto-generated review #193', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (285, 9, 6, 1, 'Auto-generated review #194', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (69, 20, 2, 3, 'Auto-generated review #195', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (241, 16, 10, 4, 'Auto-generated review #196', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (59, 14, 3, 1, 'Auto-generated review #197', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (191, 12, 6, 5, 'Auto-generated review #198', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (162, 16, 10, 3, 'Auto-generated review #199', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (202, 16, 10, 5, 'Auto-generated review #200', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (159, 8, 6, 4, 'Auto-generated review #201', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (172, 12, 6, 3, 'Auto-generated review #202', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (77, 20, 1, 1, 'Auto-generated review #203', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (393, 17, 6, 2, 'Auto-generated review #204', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (112, 6, 1, 2, 'Auto-generated review #205', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (395, 14, 8, 5, 'Auto-generated review #206', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (134, 9, 5, 1, 'Auto-generated review #207', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (133, 5, 6, 2, 'Auto-generated review #208', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (354, 19, 7, 1, 'Auto-generated review #209', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (364, 14, 7, 2, 'Auto-generated review #210', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (1, 8, 6, 1, 'Auto-generated review #211', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (27, 10, 1, 1, 'Auto-generated review #212', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (330, 18, 7, 4, 'Auto-generated review #213', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (220, 18, 6, 1, 'Auto-generated review #214', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (62, 10, 10, 1, 'Auto-generated review #215', DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (64, 6, 2, 4, 'Auto-generated review #216', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (184, 7, 10, 2, 'Auto-generated review #217', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (6, 8, 5, 1, 'Auto-generated review #218', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (84, 11, 8, 1, 'Auto-generated review #219', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (42, 12, 5, 5, 'Auto-generated review #220', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (174, 8, 3, 3, 'Auto-generated review #221', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (234, 9, 9, 1, 'Auto-generated review #222', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (347, 16, 8, 1, 'Auto-generated review #223', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (121, 12, 10, 2, 'Auto-generated review #224', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (196, 20, 4, 4, 'Auto-generated review #225', DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (275, 20, 10, 5, 'Auto-generated review #226', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (308, 8, 7, 3, 'Auto-generated review #227', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (209, 6, 5, 3, 'Auto-generated review #228', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (188, 16, 1, 5, 'Auto-generated review #229', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (316, 5, 3, 4, 'Auto-generated review #230', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (245, 18, 7, 4, 'Auto-generated review #231', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (342, 9, 9, 1, 'Auto-generated review #232', DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (104, 8, 1, 2, 'Auto-generated review #233', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (89, 7, 4, 2, 'Auto-generated review #234', DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (119, 6, 9, 5, 'Auto-generated review #235', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (218, 10, 9, 3, 'Auto-generated review #236', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (138, 19, 5, 5, 'Auto-generated review #237', DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (267, 13, 8, 1, 'Auto-generated review #238', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (250, 15, 8, 5, 'Auto-generated review #239', DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Review (reservation_ID, user_ID, restaurant_ID, reviewRating, reviewComment, reviewCreatedAt) VALUES (21, 12, 7, 5, 'Auto-generated review #240', DATE_SUB(NOW(), INTERVAL 8 DAY));

-- INSERT PAYMENT EVENTS:
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (3, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (5, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (7, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (9, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (12, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (17, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (18, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (21, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (22, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (26, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (30, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (32, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (33, 'LateCancellation', 30.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (34, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (41, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (43, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (46, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (47, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (48, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (52, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (55, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (57, 'LateCancellation', 25.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (58, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (60, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (62, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (65, 'LateCancellation', 25.00, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (69, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (70, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (71, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (72, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (73, 'LateCancellation', 30.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (74, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (75, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (77, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (78, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (79, 'LateCancellation', 25.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (84, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (86, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (87, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (88, 'LateCancellation', 25.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (92, 'LateCancellation', 30.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (97, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (99, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (103, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (105, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (108, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (109, 'LateCancellation', 25.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (110, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (111, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (114, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (115, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (122, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (123, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (124, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (125, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (126, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (127, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (128, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (134, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (137, 'LateCancellation', 25.00, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (138, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (139, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (140, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (141, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (142, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (144, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (146, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (152, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (155, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (157, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (161, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (163, 'LateCancellation', 30.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (167, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (171, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (174, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (175, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (177, 'LateCancellation', 30.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (179, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (180, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (182, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (183, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (184, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (185, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (190, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (191, 'LateCancellation', 30.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (195, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (197, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (199, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (203, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (204, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (207, 'LateCancellation', 25.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (209, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (212, 'LateCancellation', 25.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (213, 'LateCancellation', 25.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (214, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (215, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (218, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (219, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (224, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (227, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (228, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (230, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (232, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (234, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (235, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (240, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (241, 'LateCancellation', 25.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (243, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (245, 'LateCancellation', 30.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (246, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (248, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (249, 'LateCancellation', 25.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (254, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (255, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (256, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (258, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (259, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (263, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (264, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (265, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (267, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (268, 'LateCancellation', 30.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (271, 'LateCancellation', 30.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (278, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (279, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (280, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (281, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (284, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (290, 'LateCancellation', 30.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (292, 'LateCancellation', 25.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (294, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (296, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (298, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (299, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (302, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (303, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (306, 'LateCancellation', 30.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (308, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (309, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (312, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (315, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (317, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (319, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (320, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (328, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (329, 'LateCancellation', 30.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (331, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (335, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (336, 'LateCancellation', 25.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (338, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (339, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (340, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (343, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (344, 'LateCancellation', 30.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (346, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (347, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (348, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (353, 'LateCancellation', 25.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (355, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (357, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (358, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (360, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (361, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (370, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (375, 'NoShow', 20.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (376, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (378, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (381, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (382, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (383, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (384, 'LateCancellation', 20.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (387, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (389, 'LateCancellation', 50.00, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (391, 'NoShow', 25.00, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (392, 'NoShow', 30.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (395, 'NoShow', 50.00, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (396, 'LateCancellation', 10.00, DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO Paymentevent (reservation_ID, paymentEventType, paymentEventAmount, paymentEventTime) VALUES (397, 'NoShow', 10.00, DATE_SUB(NOW(), INTERVAL 2 DAY));

-- INSERT PHOTOS:
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (1, 'https://example.com/photos/restaurant_1_1.jpg', DATE_SUB(NOW(), INTERVAL 47 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (1, 'https://example.com/photos/restaurant_1_2.jpg', DATE_SUB(NOW(), INTERVAL 59 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (2, 'https://example.com/photos/restaurant_2_1.jpg', DATE_SUB(NOW(), INTERVAL 21 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (2, 'https://example.com/photos/restaurant_2_2.jpg', DATE_SUB(NOW(), INTERVAL 47 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (3, 'https://example.com/photos/restaurant_3_1.jpg', DATE_SUB(NOW(), INTERVAL 43 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (3, 'https://example.com/photos/restaurant_3_2.jpg', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (4, 'https://example.com/photos/restaurant_4_1.jpg', DATE_SUB(NOW(), INTERVAL 37 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (4, 'https://example.com/photos/restaurant_4_2.jpg', DATE_SUB(NOW(), INTERVAL 41 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (5, 'https://example.com/photos/restaurant_5_1.jpg', DATE_SUB(NOW(), INTERVAL 20 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (5, 'https://example.com/photos/restaurant_5_2.jpg', DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (6, 'https://example.com/photos/restaurant_6_1.jpg', DATE_SUB(NOW(), INTERVAL 20 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (6, 'https://example.com/photos/restaurant_6_2.jpg', DATE_SUB(NOW(), INTERVAL 37 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (7, 'https://example.com/photos/restaurant_7_1.jpg', DATE_SUB(NOW(), INTERVAL 21 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (7, 'https://example.com/photos/restaurant_7_2.jpg', DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (8, 'https://example.com/photos/restaurant_8_1.jpg', DATE_SUB(NOW(), INTERVAL 19 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (8, 'https://example.com/photos/restaurant_8_2.jpg', DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (9, 'https://example.com/photos/restaurant_9_1.jpg', DATE_SUB(NOW(), INTERVAL 51 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (9, 'https://example.com/photos/restaurant_9_2.jpg', DATE_SUB(NOW(), INTERVAL 51 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (10, 'https://example.com/photos/restaurant_10_1.jpg', DATE_SUB(NOW(), INTERVAL 13 DAY));
INSERT INTO Photo (restaurant_ID, photoURL, photoUploadedAt) VALUES (10, 'https://example.com/photos/restaurant_10_2.jpg', DATE_SUB(NOW(), INTERVAL 32 DAY));

-- INSERT FAVORITES:
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (5, 7, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (5, 1, DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (5, 9, DATE_SUB(NOW(), INTERVAL 18 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (6, 1, DATE_SUB(NOW(), INTERVAL 20 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (6, 5, DATE_SUB(NOW(), INTERVAL 15 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (6, 6, DATE_SUB(NOW(), INTERVAL 11 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (7, 3, DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (8, 4, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (9, 8, DATE_SUB(NOW(), INTERVAL 11 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (9, 2, DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (9, 1, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (10, 4, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (11, 3, DATE_SUB(NOW(), INTERVAL 3 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (11, 5, DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (12, 6, DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (12, 9, DATE_SUB(NOW(), INTERVAL 12 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (12, 2, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (13, 7, DATE_SUB(NOW(), INTERVAL 1 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (13, 8, DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (14, 3, DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (15, 4, DATE_SUB(NOW(), INTERVAL 12 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (15, 2, DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (15, 9, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (16, 6, DATE_SUB(NOW(), INTERVAL 12 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (16, 3, DATE_SUB(NOW(), INTERVAL 14 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (16, 10, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (17, 7, DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (17, 9, DATE_SUB(NOW(), INTERVAL 18 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (17, 4, DATE_SUB(NOW(), INTERVAL 13 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (18, 3, DATE_SUB(NOW(), INTERVAL 7 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (18, 7, DATE_SUB(NOW(), INTERVAL 2 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (18, 4, DATE_SUB(NOW(), INTERVAL 19 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (19, 8, DATE_SUB(NOW(), INTERVAL 9 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (19, 1, DATE_SUB(NOW(), INTERVAL 11 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (20, 8, DATE_SUB(NOW(), INTERVAL 0 DAY));
INSERT INTO Favorite (user_ID, restaurant_ID, favoriteAddedAt) VALUES (20, 4, DATE_SUB(NOW(), INTERVAL 1 DAY));
