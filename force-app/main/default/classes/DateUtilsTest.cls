@IsTest
public class DateUtilsTest {

    @IsTest
    static void testCustomFormat() {
        System.assertEquals(
                '02/06/2020',
                DateUtils.format(Date.newInstance(2020, 6, 2), 'dd/MM/yyyy')
        );
    }

    @IsTest
    static void testDefaultFormatDate() {
        System.assertEquals(
                '06/02/2020',
                DateUtils.format(Date.newInstance(2020, 6, 2))
        );
    }

    @IsTest
    static void testDefaultFormatDatetime() {
        System.assertEquals(
                '06/02/2020',
                DateUtils.format(Datetime.newInstance(2020, 6, 2))
        );
    }

    @IsTest
    static void testFormatWithTimeDatetime() {
        System.assertEquals(
                '06/02/2020 05:04:33',
                DateUtils.formatWithTime(Datetime.newInstance(2020, 6, 2, 5, 4, 33))
        );
    }

    @IsTest
    static void testGetPacificLocalDate() {
        final User userTokio = TestDataFactory.createUser('testTokioUser@wrike.com', false);
        userTokio.Username = 'testTokioUser@wrike.com';
        userTokio.TimeZoneSidKey = 'Asia/Tokyo';

        final Date dateTokio;

        System.runAs(userTokio) {
            dateTokio = DateUtils.getPacificLocalDate();
        }

        final User userGMT = TestDataFactory.createUser('testGMTUser@wrike.com', false);
        userGMT.Username = 'testGMTUser@wrike.com';
        userGMT.TimeZoneSidKey = 'GMT';

        final Date dateGMT;

        System.runAs(userGMT) {
            dateGMT = DateUtils.getPacificLocalDate();
        }

        final User userPacific = TestDataFactory.createUser('testPacificUser@wrike.com', false);
        userPacific.Username = 'testPacificUser@wrike.com';
        userPacific.TimeZoneSidKey = 'America/Los_Angeles';

        final Date datePacific;

        System.runAs(userPacific) {
            datePacific = DateUtils.getPacificLocalDate();

            System.assertEquals(Date.today(), dateGMT);
            System.assertEquals(Date.today(), dateTokio);
            System.assertEquals(Date.today(), datePacific);
        }
    }

    @IsTest
    static void testParse() {
        final Date parsedDate = DateUtils.parse('02/06/2020/');
        System.assertEquals(2, parsedDate.month());
        System.assertEquals(6, parsedDate.day());
        System.assertEquals(2020, parsedDate.year());
    }

    @IsTest
    static void testIsDatesInSameMonth() {
        System.assertEquals(false, DateUtils.isDatesInSameMonth(
                Date.newInstance(2019, 6, 12),
                Date.newInstance(2020, 6, 12)
        ));
        System.assertEquals(false, DateUtils.isDatesInSameMonth(
                Date.newInstance(2020, 5, 12),
                Date.newInstance(2020, 6, 12)
        ));
        System.assertEquals(true, DateUtils.isDatesInSameMonth(
                Date.newInstance(2020, 6, 12),
                Date.newInstance(2020, 6, 13)
        ));
    }

    @IsTest
    static void testValueOf() {
        System.assertEquals(
                Date.newInstance(2020, 6, 2),
                DateUtils.valueOf('2020-06-02 00:00:00')
        );
    }
}