-- 古いテーブルが存在する場合に備えて削除 (テスト環境なので問題ない想定)
-- もし既存データを残したい場合は、DROP TABLEは実行しないでください。
-- あるいは、IF EXISTS を使用して条件付きで削除します。
DROP TABLE IF EXISTS book_genres;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS authors;
DROP TABLE IF EXISTS genres;

-- 著者テーブル
CREATE TABLE IF NOT EXISTS authors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    biography TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ジャンルテーブル
CREATE TABLE IF NOT EXISTS genres (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 書籍テーブル
CREATE TABLE IF NOT EXISTS books (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author_id INT,
    publication_year INT,
    isbn VARCHAR(20) UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES authors(id) ON DELETE SET NULL -- 著者が削除された場合、書籍のauthor_idをNULLにする
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 書籍とジャンルの中間テーブル (多対多リレーション)
CREATE TABLE IF NOT EXISTS book_genres (
    book_id INT,
    genre_id INT,
    PRIMARY KEY (book_id, genre_id), -- 複合主キー
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE, -- 書籍が削除されたら、この関連も削除
    FOREIGN KEY (genre_id) REFERENCES genres(id) ON DELETE CASCADE  -- ジャンルが削除されたら、この関連も削除
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- サンプルデータの挿入

-- 著者データ
INSERT INTO authors (name, biography) VALUES
('夏目 漱石', '日本の小説家、評論家、英文学者。本名は夏目金之助（なつめ きんのすけ）。'),
('芥川 龍之介', '日本の小説家。号は澄江堂主人、俳号は我鬼。'),
('George Orwell', 'An English novelist, essayist, journalist and critic.');

-- ジャンルデータ
INSERT INTO genres (name) VALUES
('小説'),
('SF'),
('歴史'),
('エッセイ'),
('ディストピア');

-- 書籍データ
-- (IDはAUTO_INCREMENTなので指定不要)
INSERT INTO books (title, author_id, publication_year, isbn, description) VALUES
('こころ', (SELECT id FROM authors WHERE name = '夏目 漱石'), 1914, '978-410101001こころ', '先生と私、親友Kの葛藤を描く。'),
('羅生門', (SELECT id FROM authors WHERE name = '芥川 龍之介'), 1915, '978-410102001羅生門', '老婆と下人の出会いを描いた短編。'),
('吾輩は猫である', (SELECT id FROM authors WHERE name = '夏目 漱石'), 1905, '978-410101002吾輩', '猫の視点から人間社会を風刺。'),
('Nineteen Eighty-Four', (SELECT id FROM authors WHERE name = 'George Orwell'), 1949, '978-0451524935', 'A dystopian social science fiction novel and cautionary tale.'),
('Animal Farm', (SELECT id FROM authors WHERE name = 'George Orwell'), 1945, '978-0451526342', 'An allegorical novella reflecting events leading up to the Russian Revolution of 1917 and then on into the Stalinist era of the Soviet Union.');

-- 書籍とジャンルの関連データ
INSERT INTO book_genres (book_id, genre_id) VALUES
((SELECT id FROM books WHERE title = 'こころ'), (SELECT id FROM genres WHERE name = '小説')),
((SELECT id FROM books WHERE title = '羅生門'), (SELECT id FROM genres WHERE name = '小説')),
((SELECT id FROM books WHERE title = '羅生門'), (SELECT id FROM genres WHERE name = '歴史')), -- 例として複数ジャンル
((SELECT id FROM books WHERE title = '吾輩は猫である'), (SELECT id FROM genres WHERE name = '小説')),
((SELECT id FROM books WHERE title = 'Nineteen Eighty-Four'), (SELECT id FROM genres WHERE name = 'SF')),
((SELECT id FROM books WHERE title = 'Nineteen Eighty-Four'), (SELECT id FROM genres WHERE name = 'ディストピア')),
((SELECT id FROM books WHERE title = 'Animal Farm'), (SELECT id FROM genres WHERE name = 'SF')),
((SELECT id FROM books WHERE title = 'Animal Farm'), (SELECT id FROM genres WHERE name = 'エッセイ')); -- ジャンルはあくまで例です

-- 動作確認用 (GitHub Actionsのログで確認できます)
SELECT 'Authors count:', COUNT(*) FROM authors;
SELECT 'Books count:', COUNT(*) FROM books;
SELECT 'Genres count:', COUNT(*) FROM genres;
SELECT 'Book-Genres relations count:', COUNT(*) FROM book_genres;

SELECT
    b.title AS book_title,
    a.name AS author_name,
    GROUP_CONCAT(g.name SEPARATOR ', ') AS genres
FROM
    books b
LEFT JOIN
    authors a ON b.author_id = a.id
LEFT JOIN
    book_genres bg ON b.id = bg.book_id
LEFT JOIN
    genres g ON bg.genre_id = g.id
GROUP BY
    b.id, b.title, a.name
LIMIT 5;