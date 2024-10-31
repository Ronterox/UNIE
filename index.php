<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Educ Tool</title>
    <link rel="stylesheet" href="styles.css">

    <style>
        body {
            text-align: center;
        }

        button {
            margin: 10px;
        }

        embed {
            height: 100vh;
        }
    </style>
</head>

<body>
    <h1>Start learning now!</h1>
    <?php
    foreach (glob("output/*.html") as $filename) {
        echo "
        <button>
            <h2> Press here to open! </h2>
            <embed type='text/html' src='$filename'>
        </button>\n
        ";
    }?>
    <script>
        $ = (selector) => document.querySelectorAll(selector);

        $('button').forEach(button => {
            button.addEventListener('click', () => {
                window.location.href = button.children[1].src
            })
        });

    </script>
</body>


</html>
