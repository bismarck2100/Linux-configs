#!/usr/bin/python3
# @author: kaiwang

import requests, bs4, os, sys, subprocess


SS_PROJECT_ID = 108
SD_PROJECT_ID = 232

DEF_SINCE_DAY_CNT = 7
DEF_UNTIL_DAY_CNT = 1

LOGIN_DATA = {
    'username': 'kaiwang',
    'password': 'zaq1@wsx'
}


class BugTitleFetcher(object):
    LOGIN_URL = "https://bug.synology.com/login.php"
    URL_TEMPLATE = "https://bug.synology.com/report/report_show.php?project_id=%d&report_id=%s"

    def __init__(self):
        self.session = None

    def get_session(self):
        if not self.session:
            self.session = requests.session()
            self.session.post(self.LOGIN_URL, data=LOGIN_DATA)

        return self.session

    def get_title(self, project_id, bug_num):
        url = self.URL_TEMPLATE % (project_id, bug_num)
        session = self.get_session()
        resp = session.get(url)
        resp.raise_for_status()

        soup = bs4.BeautifulSoup(resp.text, "html.parser")
        td = soup.select_one('td[colspan="3"]')

        return td.get_text() if td else "Unknown"

class ReportGenerator(object):
    REPORT_TEMPLATE = "* #%s - %s"

    def __init__(self, since_day_cnt, until_day_cnt):
        self.fetcher = BugTitleFetcher()
        self.since_day_cnt = since_day_cnt
        self.until_day_cnt = until_day_cnt

    def run(self):
        print("[Surveillance Station]")
        self.gen_report(SS_PROJECT_ID)

        print("[Surveillance DevicePack]")
        self.gen_report(SD_PROJECT_ID)

        print("[Surveillance Support]\n")

        print("[Others]\n")

    def gen_report(self, project_id):
        for num in self.get_bug_nums(project_id):
            title = self.fetcher.get_title(project_id, num)
            print(self.REPORT_TEMPLATE % (num, title))
        print("")

    def get_bug_nums(self, project_id):
        cur_dir = os.getcwd()

        if SS_PROJECT_ID == project_id:
            work_dir = '/synosrc/Env64/source/Surveillance'
        elif SD_PROJECT_ID == project_id:
            work_dir = '/synosrc/Env64/source/SurvDevicePack'

        os.chdir(work_dir)

        cmd = r'git log --author=bismarckh --since="%s days" --until="%s days" | sed -n "s/.*#\([0-9]*\).*/\1/p" | sort | uniq' % (self.since_day_cnt, self.until_day_cnt)
        bug_nums = subprocess.check_output(cmd, universal_newlines=True, shell=True).split()

        os.chdir(cur_dir)

        return bug_nums


def show_usage():
    program = os.path.basename(sys.argv[0])
    print("Usage: %s [since_day_cnt] [until_day_cnt]\n" % (program))

def main():
    argc = len(sys.argv)

    if 1 < argc and "-h" == sys.argv[1]:
        show_usage()
    else:
        since_day_cnt = sys.argv[1] if 1 < argc else DEF_SINCE_DAY_CNT
        untile_day_cnt = sys.argv[2] if 2 < argc else DEF_UNTIL_DAY_CNT
        generator = ReportGenerator(since_day_cnt, untile_day_cnt)

        generator.run()


if "__main__" == __name__:
    main()
