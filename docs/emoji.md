
<a name="0x0_emoji"></a>

# Module `0x0::emoji`



-  [Struct `EmojiConfiguration`](#0x0_emoji_EmojiConfiguration)
-  [Struct `UTF8Emoji`](#0x0_emoji_UTF8Emoji)
-  [Struct `UTF8Character`](#0x0_emoji_UTF8Character)
-  [Constants](#@Constants_0)
-  [Function `init_emoji_config`](#0x0_emoji_init_emoji_config)
-  [Function `validate_label_with_emoji`](#0x0_emoji_validate_label_with_emoji)
-  [Function `to_emoji_sequences`](#0x0_emoji_to_emoji_sequences)
-  [Function `get_no_bytes_of_utf8`](#0x0_emoji_get_no_bytes_of_utf8)
-  [Function `to_utf8_characters`](#0x0_emoji_to_utf8_characters)
-  [Function `handle_emoji_sequence_of_two_characters`](#0x0_emoji_handle_emoji_sequence_of_two_characters)
-  [Function `handle_scalar_character`](#0x0_emoji_handle_scalar_character)
-  [Function `handle_single_byte_character`](#0x0_emoji_handle_single_byte_character)
-  [Function `handle_latin_small_g_character`](#0x0_emoji_handle_latin_small_g_character)
-  [Function `handle_variant_character`](#0x0_emoji_handle_variant_character)
-  [Function `is_emoji_sequence_of_two_characters`](#0x0_emoji_is_emoji_sequence_of_two_characters)


<pre><code><b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::vector</a>;
</code></pre>



<a name="0x0_emoji_EmojiConfiguration"></a>

## Struct `EmojiConfiguration`



<pre><code><b>struct</b> <a href="emoji.md#0x0_emoji_EmojiConfiguration">EmojiConfiguration</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>joiner: <a href="">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>variant: <a href="">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>combining_enclosing: <a href="">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>latin_small_g: <a href="">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>one_character_emojis: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>two_character_emojis: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>three_character_emojis: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>four_character_emojis: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>five_character_emojis: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>six_character_emojis: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>seven_character_emojis: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>eight_character_emojis: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>two_character_skin_tone_emojis: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>four_character_skin_tone_emojis: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>five_character_skin_tone_emojis: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>seven_character_skin_tone_emojis: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>eight_character_skin_tone_emojis: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>ten_character_skin_tone_emojis: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>skin_tones: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_emoji_UTF8Emoji"></a>

## Struct `UTF8Emoji`



<pre><code><b>struct</b> <a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>from: u64</code>
</dt>
<dd>

</dd>
<dt>
<code><b>to</b>: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>no_characters: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>is_skin_tone: bool</code>
</dt>
<dd>

</dd>
<dt>
<code>is_single_byte: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_emoji_UTF8Character"></a>

## Struct `UTF8Character`



<pre><code><b>struct</b> <a href="emoji.md#0x0_emoji_UTF8Character">UTF8Character</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>char: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>no_bytes: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_emoji_EInvalidEmojiSequence"></a>



<pre><code><b>const</b> <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>: u64 = 702;
</code></pre>



<a name="0x0_emoji_EInvalidLabel"></a>



<pre><code><b>const</b> <a href="emoji.md#0x0_emoji_EInvalidLabel">EInvalidLabel</a>: u64 = 704;
</code></pre>



<a name="0x0_emoji_init_emoji_config"></a>

## Function `init_emoji_config`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="emoji.md#0x0_emoji_init_emoji_config">init_emoji_config</a>(): <a href="emoji.md#0x0_emoji_EmojiConfiguration">emoji::EmojiConfiguration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="emoji.md#0x0_emoji_init_emoji_config">init_emoji_config</a>(): <a href="emoji.md#0x0_emoji_EmojiConfiguration">EmojiConfiguration</a> {
    <b>let</b> one_character_emojis = <a href="">vector</a>[];
    <b>let</b> two_character_emojis = <a href="">vector</a>[];
    <b>let</b> three_character_emojis = <a href="">vector</a>[];
    <b>let</b> four_character_emojis = <a href="">vector</a>[];
    <b>let</b> five_character_emojis = <a href="">vector</a>[];
    <b>let</b> six_character_emojis = <a href="">vector</a>[];
    <b>let</b> seven_character_emojis = <a href="">vector</a>[];
    <b>let</b> eight_character_emojis = <a href="">vector</a>[];
    <b>let</b> two_character_skin_tone_emojis = <a href="">vector</a>[];
    <b>let</b> four_character_skin_tone_emojis = <a href="">vector</a>[];
    <b>let</b> five_character_skin_tone_emojis = <a href="">vector</a>[];
    <b>let</b> seven_character_skin_tone_emojis = <a href="">vector</a>[];
    <b>let</b> eight_character_skin_tone_emojis = <a href="">vector</a>[];
    <b>let</b> ten_character_skin_tone_emojis = <a href="">vector</a>[];
    <b>let</b> skin_tones = <a href="">vector</a>[
        <a href="">vector</a>[240, 159, 143, 187], // light skin tone U+1F3FB
        <a href="">vector</a>[240, 159, 143, 188], // medium-light skin tone U+1F3FC
        <a href="">vector</a>[240, 159, 143, 189], // medium skin tone U+1F3FD
        <a href="">vector</a>[240, 159, 143, 190], // medium-dark skin tone U+1F3FE
        <a href="">vector</a>[240, 159, 143, 191], // dark skin tone U+1F3FF
    ];
    <a href="emoji.md#0x0_emoji_EmojiConfiguration">EmojiConfiguration</a> {
        joiner: <a href="">vector</a>[226, 128, 141], // U+200D
        variant: <a href="">vector</a>[239, 184, 143], // U+FE0F
        combining_enclosing: <a href="">vector</a>[226, 131, 163], // U+20E3
        latin_small_g: <a href="">vector</a>[243, 160, 129, 167], // U+E0067
        one_character_emojis,
        two_character_emojis,
        three_character_emojis,
        four_character_emojis,
        five_character_emojis,
        six_character_emojis,
        seven_character_emojis,
        eight_character_emojis,
        two_character_skin_tone_emojis,
        four_character_skin_tone_emojis,
        five_character_skin_tone_emojis,
        seven_character_skin_tone_emojis,
        eight_character_skin_tone_emojis,
        ten_character_skin_tone_emojis,
        skin_tones,
    }
}
</code></pre>



</details>

<a name="0x0_emoji_validate_label_with_emoji"></a>

## Function `validate_label_with_emoji`

Valid labels have 3 to 63 characters and contain only: lowercase (a-z), numbers (0-9), hyphen (-).
A name may not start or end with a hyphen

Domains registered through <code><a href="controller.md#0x0_controller">controller</a></code> have different length contraint than auctioned ones


<pre><code><b>public</b> <b>fun</b> <a href="emoji.md#0x0_emoji_validate_label_with_emoji">validate_label_with_emoji</a>(emoji_config: &<a href="emoji.md#0x0_emoji_EmojiConfiguration">emoji::EmojiConfiguration</a>, str: <a href="">vector</a>&lt;u8&gt;, min_characters: u64, max_characters: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="emoji.md#0x0_emoji_validate_label_with_emoji">validate_label_with_emoji</a>(
    emoji_config: &<a href="emoji.md#0x0_emoji_EmojiConfiguration">EmojiConfiguration</a>,
    str: <a href="">vector</a>&lt;u8&gt;,
    min_characters: u64,
    max_characters: u64
) {
    <b>let</b> emojis = <a href="emoji.md#0x0_emoji_to_emoji_sequences">to_emoji_sequences</a>(emoji_config, str);
    <b>let</b> str = utf8(str);
    <b>let</b> len = <a href="_length">vector::length</a>(&emojis);
    <b>let</b> index = 0;
    <b>assert</b>!(min_characters &lt;= len && len &lt;= max_characters, <a href="emoji.md#0x0_emoji_EInvalidLabel">EInvalidLabel</a>);

    <b>while</b> (index &lt; len) {
        <b>let</b> emoji_metadata = <a href="_borrow">vector::borrow</a>(&emojis, index);
        <b>let</b> <a href="emoji.md#0x0_emoji">emoji</a> = <a href="_sub_string">string::sub_string</a>(&str, emoji_metadata.from, emoji_metadata.<b>to</b>);
        <b>if</b> (emoji_metadata.is_single_byte) {
            <b>let</b> bytes = <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>);
            <b>let</b> byte = *<a href="_borrow">vector::borrow</a>(bytes, 0);
            <b>assert</b>!(
                (0x61 &lt;= byte && byte &lt;= 0x7A)                           // a-z
                    || (0x30 &lt;= byte && byte &lt;= 0x39)                    // 0-9
                    || (byte == 0x2D && index != 0 && index != len - 1), // - // TODO: is it correct?
                <a href="emoji.md#0x0_emoji_EInvalidLabel">EInvalidLabel</a>
            );
            index = index + 1;
            <b>continue</b>
        };

        <b>if</b> (emoji_metadata.is_skin_tone) {
            <b>if</b> (emoji_metadata.no_characters == 2)
                <b>assert</b>!(
                    <a href="_contains">vector::contains</a>(&emoji_config.two_character_skin_tone_emojis, <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>)),
                    <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
                )
            <b>else</b> <b>if</b> (emoji_metadata.no_characters == 4)
                <b>assert</b>!(
                    <a href="_contains">vector::contains</a>(&emoji_config.four_character_skin_tone_emojis, <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>)),
                    <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
                )
            <b>else</b> <b>if</b> (emoji_metadata.no_characters == 5)
                <b>assert</b>!(
                    <a href="_contains">vector::contains</a>(&emoji_config.five_character_skin_tone_emojis, <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>)),
                    <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
                )
            <b>else</b> <b>if</b> (emoji_metadata.no_characters == 7)
                <b>assert</b>!(
                    <a href="_contains">vector::contains</a>(&emoji_config.seven_character_skin_tone_emojis, <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>)),
                    <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
                )
            <b>else</b> <b>if</b> (emoji_metadata.no_characters == 8)
                <b>assert</b>!(
                    <a href="_contains">vector::contains</a>(&emoji_config.eight_character_skin_tone_emojis, <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>)),
                    <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
                )
            <b>else</b> <b>if</b> (emoji_metadata.no_characters == 10)
                <b>assert</b>!(
                    <a href="_contains">vector::contains</a>(&emoji_config.ten_character_skin_tone_emojis, <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>)),
                    <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
                )
            <b>else</b> <b>abort</b> <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>;
        } <b>else</b> {
            <b>if</b> (emoji_metadata.no_characters == 1)
                <b>assert</b>!(
                    <a href="_contains">vector::contains</a>(&emoji_config.one_character_emojis, <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>)),
                    <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
                )
            <b>else</b> <b>if</b> (emoji_metadata.no_characters == 2)
                <b>assert</b>!(
                    <a href="_contains">vector::contains</a>(&emoji_config.two_character_emojis, <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>)),
                    <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
                )
            <b>else</b> <b>if</b> (emoji_metadata.no_characters == 3)
                <b>assert</b>!(
                    <a href="_contains">vector::contains</a>(&emoji_config.three_character_emojis, <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>)),
                    <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
                )
            <b>else</b> <b>if</b> (emoji_metadata.no_characters == 4)
                <b>assert</b>!(
                    <a href="_contains">vector::contains</a>(&emoji_config.four_character_emojis, <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>)),
                    <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
                )
            <b>else</b> <b>if</b> (emoji_metadata.no_characters == 5)
                <b>assert</b>!(
                    <a href="_contains">vector::contains</a>(&emoji_config.five_character_emojis, <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>)),
                    <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
                )
            <b>else</b> <b>if</b> (emoji_metadata.no_characters == 6)
                <b>assert</b>!(
                    <a href="_contains">vector::contains</a>(&emoji_config.six_character_emojis, <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>)),
                    <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
                )
            <b>else</b> <b>if</b> (emoji_metadata.no_characters == 7)
                <b>assert</b>!(
                    <a href="_contains">vector::contains</a>(&emoji_config.seven_character_emojis, <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>)),
                    <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
                )
            <b>else</b> <b>if</b> (emoji_metadata.no_characters == 8)
                <b>assert</b>!(
                    <a href="_contains">vector::contains</a>(&emoji_config.eight_character_emojis, <a href="_bytes">string::bytes</a>(&<a href="emoji.md#0x0_emoji">emoji</a>)),
                    <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
                )
            <b>else</b> <b>abort</b> <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>
        };
        index = index + 1;
    };
}
</code></pre>



</details>

<a name="0x0_emoji_to_emoji_sequences"></a>

## Function `to_emoji_sequences`



<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_to_emoji_sequences">to_emoji_sequences</a>(emoji_config: &<a href="emoji.md#0x0_emoji_EmojiConfiguration">emoji::EmojiConfiguration</a>, bytes: <a href="">vector</a>&lt;u8&gt;): <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Emoji">emoji::UTF8Emoji</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_to_emoji_sequences">to_emoji_sequences</a>(emoji_config: &<a href="emoji.md#0x0_emoji_EmojiConfiguration">EmojiConfiguration</a>, bytes: <a href="">vector</a>&lt;u8&gt;): <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a>&gt; {
    <b>let</b> characters = <a href="emoji.md#0x0_emoji_to_utf8_characters">to_utf8_characters</a>(&bytes);
    <b>let</b> len = <a href="_length">vector::length</a>(&characters);
    // consider only preceding character in the same <a href="emoji.md#0x0_emoji">emoji</a> sequence
    <b>let</b> is_preceding_character_scalar = <b>false</b>;
    <b>let</b> is_skin_tone = <b>false</b>;
    <b>let</b> result = <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a>&gt;[];
    <b>let</b> index = 0;
    <b>let</b> from_index = 0;
    <b>let</b> to_index = 0;
    <b>let</b> no_characters = 0;
    <b>let</b> remaining_characters = len;

    <b>while</b> (index &lt; len) {
        <b>let</b> current_character = <a href="_borrow">vector::borrow</a>(&characters, index);
        to_index = to_index + current_character.no_bytes;
        no_characters = no_characters + 1;

        // is alphabet character
        <b>if</b> (current_character.no_bytes == 1) {
            <a href="emoji.md#0x0_emoji_handle_single_byte_character">handle_single_byte_character</a>(
                emoji_config, &<b>mut</b> result, &characters,
                &<b>mut</b> from_index, &<b>mut</b> to_index, &<b>mut</b> index,
                &<b>mut</b> remaining_characters, &<b>mut</b> is_skin_tone, &<b>mut</b> no_characters,
                &<b>mut</b> is_preceding_character_scalar, len,
            );
            <b>continue</b>
        };

        <b>if</b> (*<a href="_bytes">string::bytes</a>(&current_character.char) == emoji_config.latin_small_g) {
            <a href="emoji.md#0x0_emoji_handle_latin_small_g_character">handle_latin_small_g_character</a>(
                &<b>mut</b> result, &<b>mut</b> characters, &<b>mut</b> from_index,
                &<b>mut</b> to_index, index, &<b>mut</b> remaining_characters,
                is_skin_tone, &<b>mut</b> no_characters, &<b>mut</b> is_preceding_character_scalar,
            );
            index = index + 6;
            <b>continue</b>
        };

        <b>if</b> (<a href="_contains">vector::contains</a>(&emoji_config.skin_tones, <a href="_bytes">string::bytes</a>(&current_character.char))) {
            <b>assert</b>!(is_preceding_character_scalar, <a href="emoji.md#0x0_emoji_EInvalidEmojiSequence">EInvalidEmojiSequence</a>);
            is_skin_tone = <b>true</b>;
            <b>if</b> (index == len - 1) {
                <a href="_push_back">vector::push_back</a>(&<b>mut</b> result, <a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a> { from: from_index, <b>to</b>: to_index, no_characters, is_skin_tone, is_single_byte: <b>false</b> });
                remaining_characters = remaining_characters - no_characters;
            };
            index = index + 1;
            <b>continue</b>
        };

        <b>if</b> (<a href="emoji.md#0x0_emoji_is_emoji_sequence_of_two_characters">is_emoji_sequence_of_two_characters</a>(&current_character.char)) {
            <a href="emoji.md#0x0_emoji_handle_emoji_sequence_of_two_characters">handle_emoji_sequence_of_two_characters</a>(
                &<b>mut</b> result, &characters, &<b>mut</b> from_index,
                &<b>mut</b> to_index, index, &<b>mut</b> remaining_characters,
                &<b>mut</b> is_skin_tone, &<b>mut</b> no_characters, &<b>mut</b> is_preceding_character_scalar,
            );
            index = index + 2;
            <b>continue</b>
        };

        <b>if</b> (*<a href="_bytes">string::bytes</a>(&current_character.char) == emoji_config.variant) {
            <a href="emoji.md#0x0_emoji_handle_variant_character">handle_variant_character</a>(
                emoji_config, &<b>mut</b> result, &characters,
                &<b>mut</b> from_index, to_index, index,
                &<b>mut</b> remaining_characters, &<b>mut</b> is_skin_tone,
                &<b>mut</b> no_characters, &<b>mut</b> is_preceding_character_scalar, len
            );
            index = index + 1;
            <b>continue</b>
        };

        <b>if</b> (*<a href="_bytes">string::bytes</a>(&current_character.char) != emoji_config.joiner) {
            <a href="emoji.md#0x0_emoji_handle_scalar_character">handle_scalar_character</a>(
                &<b>mut</b> result, current_character, &<b>mut</b> from_index,
                to_index, index, &<b>mut</b> remaining_characters, &<b>mut</b> is_skin_tone,
                &<b>mut</b> no_characters, is_preceding_character_scalar, len
            );
            is_preceding_character_scalar = <b>true</b>;
        } <b>else</b> is_preceding_character_scalar = <b>false</b>;

        index = index + 1;
    };
    <b>assert</b>!(remaining_characters == 0, <a href="emoji.md#0x0_emoji_EInvalidLabel">EInvalidLabel</a>);
    result
}
</code></pre>



</details>

<a name="0x0_emoji_get_no_bytes_of_utf8"></a>

## Function `get_no_bytes_of_utf8`



<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_get_no_bytes_of_utf8">get_no_bytes_of_utf8</a>(first_byte: u8): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_get_no_bytes_of_utf8">get_no_bytes_of_utf8</a>(first_byte: u8): u64 {
    <b>if</b> (first_byte &lt;= 127) <b>return</b> 1;
    <b>if</b> (192 &lt;= first_byte && first_byte &lt;= 223) <b>return</b> 2;
    <b>if</b> (224 &lt;= first_byte && first_byte &lt;= 239) <b>return</b> 3;
    <b>if</b> (240 &lt;= first_byte && first_byte &lt;= 247) <b>return</b> 4;
    <b>abort</b>(<a href="emoji.md#0x0_emoji_EInvalidLabel">EInvalidLabel</a>)
}
</code></pre>



</details>

<a name="0x0_emoji_to_utf8_characters"></a>

## Function `to_utf8_characters`



<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_to_utf8_characters">to_utf8_characters</a>(bytes: &<a href="">vector</a>&lt;u8&gt;): <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Character">emoji::UTF8Character</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_to_utf8_characters">to_utf8_characters</a>(bytes: &<a href="">vector</a>&lt;u8&gt;): <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Character">UTF8Character</a>&gt; {
    <b>let</b> str = utf8(*bytes);
    <b>let</b> result = <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Character">UTF8Character</a>&gt;[];
    <b>let</b> index = 0;
    <b>let</b> no_bytes = <a href="_length">vector::length</a>(bytes);

    <b>while</b> (index &lt; no_bytes) {
        <b>let</b> first_byte = *<a href="_borrow">vector::borrow</a>(bytes, index);
        <b>let</b> no_bytes = <a href="emoji.md#0x0_emoji_get_no_bytes_of_utf8">get_no_bytes_of_utf8</a>(first_byte);
        <b>let</b> c = <a href="_sub_string">string::sub_string</a>(&str, index, index + no_bytes);
        <a href="_push_back">vector::push_back</a>(&<b>mut</b> result, <a href="emoji.md#0x0_emoji_UTF8Character">UTF8Character</a> { char: c, no_bytes });

        index = index + no_bytes;
    };

    result
}
</code></pre>



</details>

<a name="0x0_emoji_handle_emoji_sequence_of_two_characters"></a>

## Function `handle_emoji_sequence_of_two_characters`



<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_handle_emoji_sequence_of_two_characters">handle_emoji_sequence_of_two_characters</a>(result: &<b>mut</b> <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Emoji">emoji::UTF8Emoji</a>&gt;, characters: &<a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Character">emoji::UTF8Character</a>&gt;, from_index: &<b>mut</b> u64, to_index: &<b>mut</b> u64, index: u64, remaining_characters: &<b>mut</b> u64, is_skin_tone: &<b>mut</b> bool, no_characters: &<b>mut</b> u64, is_preceding_character_scalar: &<b>mut</b> bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_handle_emoji_sequence_of_two_characters">handle_emoji_sequence_of_two_characters</a>(
    result: &<b>mut</b> <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a>&gt;,
    characters: &<a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Character">UTF8Character</a>&gt;,
    from_index: &<b>mut</b> u64,
    to_index: &<b>mut</b> u64,
    index: u64,
    remaining_characters: &<b>mut</b> u64,
    is_skin_tone: &<b>mut</b> bool,
    no_characters: &<b>mut</b> u64,
    is_preceding_character_scalar: &<b>mut</b> bool,
) {
    <b>let</b> next_character = <a href="_borrow">vector::borrow</a>(characters, index + 1);
    *to_index = *to_index + next_character.no_bytes;
    <a href="_push_back">vector::push_back</a>(result, <a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a> {
        from: *from_index,
        <b>to</b>: *to_index,
        no_characters: 2,
        is_skin_tone: *is_skin_tone,
        is_single_byte: <b>false</b>
    });
    *no_characters = 0;
    *is_skin_tone = <b>false</b>;
    *from_index = *to_index;
    *remaining_characters = *remaining_characters - 2;
    *is_preceding_character_scalar = <b>false</b>;
}
</code></pre>



</details>

<a name="0x0_emoji_handle_scalar_character"></a>

## Function `handle_scalar_character`



<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_handle_scalar_character">handle_scalar_character</a>(result: &<b>mut</b> <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Emoji">emoji::UTF8Emoji</a>&gt;, current_character: &<a href="emoji.md#0x0_emoji_UTF8Character">emoji::UTF8Character</a>, from_index: &<b>mut</b> u64, to_index: u64, index: u64, remaining_characters: &<b>mut</b> u64, is_skin_tone: &<b>mut</b> bool, no_characters: &<b>mut</b> u64, is_preceding_character_scalar: bool, len: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_handle_scalar_character">handle_scalar_character</a>(
    result: &<b>mut</b> <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a>&gt;,
    current_character: &<a href="emoji.md#0x0_emoji_UTF8Character">UTF8Character</a>,
    from_index: &<b>mut</b> u64,
    to_index: u64,
    index: u64,
    remaining_characters: &<b>mut</b> u64,
    is_skin_tone: &<b>mut</b> bool,
    no_characters: &<b>mut</b> u64,
    is_preceding_character_scalar: bool,
    len: u64
) {
    <b>if</b> (is_preceding_character_scalar) {
        // 2 scalar characters cannot stand next <b>to</b> each other in a <a href="emoji.md#0x0_emoji">emoji</a> sequence,
        // so the previous scalar character is the end of its <a href="emoji.md#0x0_emoji">emoji</a> sequence
        <b>let</b> bytes = <a href="_bytes">string::bytes</a>(&current_character.char);
        <a href="_push_back">vector::push_back</a>(result, <a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a> {
            from: *from_index,
            <b>to</b>: to_index - <a href="_length">vector::length</a>(bytes),
            no_characters: *no_characters - 1,
            is_skin_tone: *is_skin_tone,
            is_single_byte: <b>false</b>
        });
        *remaining_characters = *remaining_characters - *no_characters + 1;
        *no_characters = 1;
        *is_skin_tone = <b>false</b>;
        *from_index = to_index - <a href="_length">vector::length</a>(bytes);
    };
    <b>if</b> (index == len - 1) {
        <a href="_push_back">vector::push_back</a>(result, <a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a> {
            from: *from_index,
            <b>to</b>: to_index,
            no_characters: *no_characters,
            is_skin_tone: *is_skin_tone,
            is_single_byte: <b>false</b>
        });
        *remaining_characters = *remaining_characters - *no_characters;
    };
}
</code></pre>



</details>

<a name="0x0_emoji_handle_single_byte_character"></a>

## Function `handle_single_byte_character`



<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_handle_single_byte_character">handle_single_byte_character</a>(emoji_config: &<a href="emoji.md#0x0_emoji_EmojiConfiguration">emoji::EmojiConfiguration</a>, result: &<b>mut</b> <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Emoji">emoji::UTF8Emoji</a>&gt;, characters: &<a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Character">emoji::UTF8Character</a>&gt;, from_index: &<b>mut</b> u64, to_index: &<b>mut</b> u64, index: &<b>mut</b> u64, remaining_characters: &<b>mut</b> u64, is_skin_tone: &<b>mut</b> bool, no_characters: &<b>mut</b> u64, is_preceding_character_scalar: &<b>mut</b> bool, len: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_handle_single_byte_character">handle_single_byte_character</a>(
    emoji_config: &<a href="emoji.md#0x0_emoji_EmojiConfiguration">EmojiConfiguration</a>,
    result: &<b>mut</b> <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a>&gt;,
    characters: &<a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Character">UTF8Character</a>&gt;,
    from_index: &<b>mut</b> u64,
    to_index: &<b>mut</b> u64,
    index: &<b>mut</b> u64,
    remaining_characters: &<b>mut</b> u64,
    is_skin_tone: &<b>mut</b> bool,
    no_characters: &<b>mut</b> u64,
    is_preceding_character_scalar: &<b>mut</b> bool,
    len: u64,
) {
    <b>if</b> (*no_characters &gt; 1) {
        <a href="_push_back">vector::push_back</a>(result, <a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a> {
            from: *from_index,
            <b>to</b>: *to_index - 1,
            no_characters: *no_characters - 1,
            is_skin_tone: *is_skin_tone,
            is_single_byte: <b>false</b>,
        });
        *from_index = *to_index - 1;
        *remaining_characters = *remaining_characters + 1 - *no_characters;
    };
    // check for special cases that end <b>with</b> u+20e3, i.e. 0023_fe0f_20e3
    <b>if</b> (*index &lt; len - 2) {
        <b>let</b> next_next_character = <a href="_borrow">vector::borrow</a>(characters, *index + 2);
        <b>let</b> bytes = <a href="_bytes">string::bytes</a>(&next_next_character.char);
        <b>if</b> (*bytes == emoji_config.combining_enclosing) {
            <b>assert</b>!(!*is_skin_tone, <a href="emoji.md#0x0_emoji_EInvalidLabel">EInvalidLabel</a>);
            <b>let</b> next_character = <a href="_borrow">vector::borrow</a>(characters, *index + 2);
            *to_index = *to_index + next_character.no_bytes;
            *to_index = *to_index + next_next_character.no_bytes;
            <a href="_push_back">vector::push_back</a>(
                result,
                <a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a> {
                    from: *from_index,
                    <b>to</b>: *to_index,
                    no_characters: 3,
                    is_skin_tone: *is_skin_tone,
                    is_single_byte: <b>false</b>
                }
            );
            *remaining_characters = *remaining_characters - 3;
            *no_characters = 0;
            *from_index = *to_index;
            *index = *index + 3;
            *is_preceding_character_scalar = <b>false</b>;
            <b>return</b>
        };
    };
    <a href="_push_back">vector::push_back</a>(
        result,
        <a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a> {
            from: *to_index - 1,
            <b>to</b>: *to_index,
            no_characters: 1,
            is_skin_tone: *is_skin_tone,
            is_single_byte: <b>true</b>
        }
    );
    *remaining_characters = *remaining_characters - 1;
    *from_index = *to_index;
    *is_skin_tone = <b>false</b>;
    *no_characters = 0;
    *is_preceding_character_scalar = <b>false</b>;
    *index = *index + 1;
}
</code></pre>



</details>

<a name="0x0_emoji_handle_latin_small_g_character"></a>

## Function `handle_latin_small_g_character`



<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_handle_latin_small_g_character">handle_latin_small_g_character</a>(result: &<b>mut</b> <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Emoji">emoji::UTF8Emoji</a>&gt;, characters: &<a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Character">emoji::UTF8Character</a>&gt;, from_index: &<b>mut</b> u64, to_index: &<b>mut</b> u64, index: u64, remaining_characters: &<b>mut</b> u64, is_skin_tone: bool, no_characters: &<b>mut</b> u64, is_preceding_character_scalar: &<b>mut</b> bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_handle_latin_small_g_character">handle_latin_small_g_character</a>(
    result: &<b>mut</b> <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a>&gt;,
    characters: &<a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Character">UTF8Character</a>&gt;,
    from_index: &<b>mut</b> u64,
    to_index: &<b>mut</b> u64,
    index: u64,
    remaining_characters: &<b>mut</b> u64,
    is_skin_tone: bool,
    no_characters: &<b>mut</b> u64,
    is_preceding_character_scalar: &<b>mut</b> bool,
) {
    // special cases, i.e. 1f3f4_e0067_e0062_e0065_e006e_e0067_e007f
    // <b>if</b> matches <b>with</b> E0067 =&gt; the next 5 characters are in the same <a href="emoji.md#0x0_emoji">emoji</a> sequence
    <b>assert</b>!(!is_skin_tone, <a href="emoji.md#0x0_emoji_EInvalidLabel">EInvalidLabel</a>);
    <b>assert</b>!(*no_characters == 2, <a href="emoji.md#0x0_emoji_EInvalidLabel">EInvalidLabel</a>);
    <b>let</b> i = 1;
    <b>while</b> (i &lt;= 5) {
        <b>let</b> character = <a href="_borrow">vector::borrow</a>(characters, index + i);
        *to_index = *to_index + character.no_bytes;
        i = i + 1;
    };
    <a href="_push_back">vector::push_back</a>(result, <a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a> {
        from: *from_index,
        <b>to</b>: *to_index,
        no_characters: 7,
        is_skin_tone,
        is_single_byte: <b>false</b>,
    });
    *remaining_characters = *remaining_characters - 7;
    *from_index = *to_index;
    *no_characters = 0;
    *is_preceding_character_scalar = <b>false</b>;
}
</code></pre>



</details>

<a name="0x0_emoji_handle_variant_character"></a>

## Function `handle_variant_character`



<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_handle_variant_character">handle_variant_character</a>(emoji_config: &<a href="emoji.md#0x0_emoji_EmojiConfiguration">emoji::EmojiConfiguration</a>, result: &<b>mut</b> <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Emoji">emoji::UTF8Emoji</a>&gt;, characters: &<a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Character">emoji::UTF8Character</a>&gt;, from_index: &<b>mut</b> u64, to_index: u64, index: u64, remaining_characters: &<b>mut</b> u64, is_skin_tone: &<b>mut</b> bool, no_characters: &<b>mut</b> u64, is_preceding_character_scalar: &<b>mut</b> bool, len: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_handle_variant_character">handle_variant_character</a>(
    emoji_config: &<a href="emoji.md#0x0_emoji_EmojiConfiguration">EmojiConfiguration</a>,
    result: &<b>mut</b> <a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a>&gt;,
    characters: &<a href="">vector</a>&lt;<a href="emoji.md#0x0_emoji_UTF8Character">UTF8Character</a>&gt;,
    from_index: &<b>mut</b> u64,
    to_index: u64,
    index: u64,
    remaining_characters: &<b>mut</b> u64,
    is_skin_tone: &<b>mut</b> bool,
    no_characters: &<b>mut</b> u64,
    is_preceding_character_scalar: &<b>mut</b> bool,
    len: u64
) {
    // variant character is either at the last position, or followed by the joiner character
    <b>if</b> (index &lt; len - 1) {
        <b>let</b> next_character = <a href="_borrow">vector::borrow</a>(characters, index + 1);
        <b>if</b> (*<a href="_bytes">string::bytes</a>(&next_character.char) != emoji_config.joiner) {
            <a href="_push_back">vector::push_back</a>(
                result,
                <a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a> {
                    from: *from_index,
                    <b>to</b>: to_index,
                    no_characters: *no_characters,
                    is_skin_tone: *is_skin_tone,
                    is_single_byte: <b>false</b>
                }
            );
            *remaining_characters = *remaining_characters - *no_characters;
            *no_characters = 0;
            *from_index = to_index;
            *is_skin_tone = <b>false</b>;
        };
        *is_preceding_character_scalar = <b>false</b>;
    } <b>else</b> {
        // this variant character is at the end of the input <a href="">string</a>,
        // so this <a href="emoji.md#0x0_emoji">emoji</a> sequence <b>has</b> <b>to</b> end here
        <a href="_push_back">vector::push_back</a>(
            result,
            <a href="emoji.md#0x0_emoji_UTF8Emoji">UTF8Emoji</a> {
                from: *from_index,
                <b>to</b>: to_index,
                no_characters: *no_characters,
                is_skin_tone: *is_skin_tone,
                is_single_byte: <b>false</b>
            }
        );
        *remaining_characters = *remaining_characters - *no_characters;
    };
}
</code></pre>



</details>

<a name="0x0_emoji_is_emoji_sequence_of_two_characters"></a>

## Function `is_emoji_sequence_of_two_characters`



<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_is_emoji_sequence_of_two_characters">is_emoji_sequence_of_two_characters</a>(str: &<a href="_String">string::String</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="emoji.md#0x0_emoji_is_emoji_sequence_of_two_characters">is_emoji_sequence_of_two_characters</a>(str: &String): bool {
    <b>let</b> bytes = <a href="_bytes">string::bytes</a>(str);
    <b>if</b> (<a href="_length">vector::length</a>(bytes) != 4) <b>return</b> <b>false</b>;

    <b>let</b> first_byte = *<a href="_borrow">vector::borrow</a>(bytes, 0);
    <b>if</b> (first_byte != 240) <b>return</b> <b>false</b>;

    <b>let</b> second_byte = *<a href="_borrow">vector::borrow</a>(bytes, 1);
    <b>if</b> (second_byte != 159) <b>return</b> <b>false</b>;

    <b>let</b> third_byte = *<a href="_borrow">vector::borrow</a>(bytes, 2);
    <b>if</b> (third_byte != 135) <b>return</b> <b>false</b>;

    <b>let</b> fourth_byte = *<a href="_borrow">vector::borrow</a>(bytes, 3);
    <b>if</b> (166 &lt;= fourth_byte && fourth_byte &lt;= 191) <b>return</b> <b>true</b>;
    <b>false</b>
}
</code></pre>



</details>
