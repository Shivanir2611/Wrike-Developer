@IsTest
public class EmailUtilTest {
    
    @IsTest
    public static void testValidEmail() {
        System.assert(EmailUtil.isValidEmail('test.user@gmail.com'), 'Email should be valid.');
        System.assert(EmailUtil.isValidEmail('test.user@team.wrike.com'), 'Email should be valid.');
        System.assert(EmailUtil.isValidEmail('test.user@team.wrike.com'), 'Email should be valid.');
        System.assert(EmailUtil.isValidEmail('email@example.com'), 'Email should be valid.');
        System.assert(EmailUtil.isValidEmail('firstname.lastname@example.com'), 'Email should be valid.');
        System.assert(EmailUtil.isValidEmail('email@subdomain.example.com'), 'Email should be valid.');
        System.assert(EmailUtil.isValidEmail('firstname+lastname@example.com'), 'Email should be valid.');
        System.assert(EmailUtil.isValidEmail('1234567890@example.com'), 'Email should be valid.');
        System.assert(EmailUtil.isValidEmail('email@example-one.com'), 'Email should be valid.');
        System.assert(EmailUtil.isValidEmail('_______@example.com'), 'Email should be valid.');
        System.assert(EmailUtil.isValidEmail('email@example.name'), 'Email should be valid.');
        System.assert(EmailUtil.isValidEmail('email@example.museum'), 'Email should be valid.');
        System.assert(EmailUtil.isValidEmail('email@example.co.jp'), 'Email should be valid.');
        System.assert(EmailUtil.isValidEmail('firstname-lastname@example.com'), 'Email should be valid.');
    }
    
    @IsTest
    public static void testNotValidEmail() {
        System.assert(!EmailUtil.isValidEmail('test.user,@gmail.com'), 'Email should not be valid.');
        System.assert(!EmailUtil.isValidEmail('test.user@team.wrike.com@'), 'Email should not be valid.');
        System.assert(!EmailUtil.isValidEmail('test.user@'), 'Email should not be valid.');
        System.assert(!EmailUtil.isValidEmail('test.user'), 'Email should not be valid.');
        System.assert(!EmailUtil.isValidEmail(''), 'Email should not be valid.');
        System.assert(!EmailUtil.isValidEmail(null), 'Email should not be valid.');
        System.assert(!EmailUtil.isValidEmail('#@%^%#$@#$@#.com'), 'Email should not be valid.');
        System.assert(!EmailUtil.isValidEmail('@example.com'), 'Email should not be valid.');
        System.assert(!EmailUtil.isValidEmail('Joe Smith <email@example.com>'), 'Email should not be valid.');
        System.assert(!EmailUtil.isValidEmail('email.example.com'), 'Email should not be valid.');
        System.assert(!EmailUtil.isValidEmail('email@example@example.com'), 'Email should not be valid.');
        System.assert(!EmailUtil.isValidEmail('email@example.com (Joe Smith)'), 'Email should not be valid.');
        System.assert(!EmailUtil.isValidEmail('email@example'), 'Email should not be valid.');
    }
    
    @IsTest
    public static void testGetEmailDomain() {
        System.assertEquals('team.wrike.com', EmailUtil.getEmailDomain('test.user@team.wrike.com'));
        System.assert(EmailUtil.getEmailDomain(null) == null, 'Wrong domain for null email.');
        System.assert(EmailUtil.getEmailDomain(' ') == null, 'Wrong domain for blank email.');
        System.assert(EmailUtil.getEmailDomain('test.user#email.com') == null, 'Wrong domain for invlid email.');
        System.assert(EmailUtil.getEmailDomain('test.user@gmail.com') == null, 'Email domain should be blank for @gmail.com email.');
        System.assert(EmailUtil.getEmailDomain('test.user@sharklasers.com') == null, 'Email domain should be blank for @sharklasers.com email.');
        System.assert(EmailUtil.getEmailDomain('test.user@trbvm.com') == null, 'Email domain should be blank for @trbvm.com email.');
        System.assert(EmailUtil.getEmailDomain('test.user@yopmail.com') == null, 'Email domain should be blank for @yopmail.com email.');
        System.assert(EmailUtil.getEmailDomain('test.user@mylaurier.ca') == null, 'Email domain should be blank for @mylaurier.ca email.');
        System.assert(EmailUtil.getEmailDomain('test.user@trbvn.com') == null, 'Email domain should be blank for @trbvn.com email.');
        System.assert(EmailUtil.getEmailDomain('test.user@mvrht.com') == null, 'Email domain should be blank for @mvrht.com email.');
        System.assert(EmailUtil.getEmailDomain('test.user@astra.xlri.ac.in') == null, 'Email domain should be blank for @astra.xlri.ac.in email.');
        System.assert(EmailUtil.getEmailDomain('test.user@noicd.com') == null, 'Email domain should be blank for @noicd.com email.');
        System.assert(EmailUtil.getEmailDomain('test.user@mail.ua') == null, 'Email domain should be blank for @mail.ua email.');
        System.assert(EmailUtil.getEmailDomain('test.user@abv.bg') == null, 'Email domain should be blank for @abv.bg email.');
        System.assert(EmailUtil.getEmailDomain('test.user@protonmail.com') == null, 'Email domain should be blank for @protonmail.com email.');
        System.assert(EmailUtil.getEmailDomain('test.user@cam.ac.uk') == null, 'Email domain should be blank for @cam.ac.uk email.');
        System.assert(EmailUtil.getEmailDomain('test.user@mvrht.com') == null, 'Email domain should be blank for @mvrht.com.');
        System.assert(EmailUtil.getEmailDomain('test.user@mvrht.net') == null, 'Email domain should be blank for @mvrht.net.');
        System.assert(EmailUtil.getEmailDomain('test.user@hotmail.co.jp') == null, 'Email domain should be blank for @hotmail.co.jp.');
    }
}