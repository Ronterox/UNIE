<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Educ Tool</title>
    <link
        rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.classless.indigo.min.css">
    <script src="https://unpkg.com/hyperscript.org@0.9.13"></script>
</head>

<body>
    <main>
        <h1>Start learning now!</h1>
        <ul>
            <?php
            foreach (glob("pdf/*.pdf") as $filename) {
                $json = "json/" . pathinfo($filename, PATHINFO_FILENAME) . ".json";
                $json = preg_replace('/[[:cntrl:]]/', '', file_get_contents($json));

                if (!empty($json)) {
                    $questions = json_decode($json, true) or die("json: " . json_last_error_msg());

                    $output = "";
                    foreach ($questions as $question) {
                        $q = $question['question'];
                        $correct = $question['correct'];

                        $output .= "<legend><strong>$q</strong></legend><fieldset data-correct='$correct'>";
                        $i = 0;
                        foreach ($question['answers'] as $ans) {
                            $output .= <<<HTML
                                <label _="on click add @selected=$i to the next <input[type='button']/>">
                                    <input type='radio' name='$q' value='$i'/>
                                    $ans
                                </label>
                            HTML;
                            $i++;
                        }
                        $output .= <<<HTML
                            <input type='button' value='Submit'
                                _="on click get the closest parent @data-correct then
                                    set local aria to @selected != it then
                                    repeat in <input/>
                                        set its @aria-invalid to aria
                                        then log it
                                    end"
                            />
                            </fieldset>
                        HTML;
                    }
                }

                echo <<<HTML
                <li _="on click add @disabled to the first <input/> in me
                        then remove @hidden from the <article/> in me"
                >
                    <label _="on click add @checked to the first <input/> in me" >
                        <input type="checkbox" id="$filename"/>$filename
                    </label>

                    <div style="display: flex;">
                        <article hidden _="on mutation of @hidden
                                            get the next <embed/> then set its width to 100%">$output</article>
                        <embed style="margin-left: 1rem;" src="$filename" type="application/pdf"/>
                    </div>
                </li>
                HTML;
            } ?>
        </ul>
    </main>
</body>


</html>
